import { nextTick } from 'vue';
import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CsvUploadModal from '~/members/placeholders/components/csv_upload_modal.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import waitForPromises from 'helpers/wait_for_promises';

const csrfToken = 'mock-csrf-token';
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));

describe('CsvUploadModal', () => {
  let wrapper;

  const defaultInjectedAttributes = {
    reassignmentCsvPath: 'foo/bar',
  };

  const findDownloadLink = () => wrapper.findByTestId('csv-download-button');
  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findUploadErrorAlert = () => wrapper.findByTestId('upload-error');
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');

  function createComponent() {
    return shallowMountExtended(CsvUploadModal, {
      propsData: {
        modalId: 'csv-upload-modal',
      },
      provide: {
        ...defaultInjectedAttributes,
      },
    });
  }

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('has the CSV download button with the required attributes', () => {
    const downloadLink = findDownloadLink();

    expect(downloadLink.exists()).toBe(true);
    expect(downloadLink.attributes('href')).toBe(defaultInjectedAttributes.reassignmentCsvPath);
  });

  describe('CSV upload', () => {
    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsText');
    });

    it('renders the upload dropzone', () => {
      expect(findUploadDropzone().exists()).toBe(true);
    });

    it('displays an error when the dropzone emits an error', async () => {
      findUploadDropzone().vm.$emit('error');

      await nextTick();

      expect(findUploadErrorAlert().exists()).toBe(true);
      expect(findUploadErrorAlert().text()).toBe(
        'Unable to upload the file. Check that the file follows the CSV template and try again.',
      );
    });

    it('accepts CSV files for the dropzone', () => {
      const uploadDropzone = findUploadDropzone();
      const isFileValid = uploadDropzone.props('isFileValid');
      expect(isFileValid({ name: 'upload.csv' })).toBe(true);
    });

    it.each(['.pdf', '.jpg', '.html'])('rejects %s file extension', (extension) => {
      const uploadDropzone = findUploadDropzone();
      const isFileValid = uploadDropzone.props('isFileValid');
      expect(isFileValid({ name: `upload${extension}` })).toBe(false);
    });

    describe('form', () => {
      it('has the correct action', () => {
        const form = findForm();

        expect(form.attributes('action')).toBe(defaultInjectedAttributes.reassignmentCsvPath);
      });

      it('has the correct form data', async () => {
        const uploadDropzone = findUploadDropzone();
        const form = findForm();
        const file = new File(['test'], 'file.csv');

        uploadDropzone.vm.$emit('change', file);
        await waitForPromises();

        expect(FileReader.prototype.readAsText).toHaveBeenCalledWith(file);

        await waitForPromises();
        expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(csrfToken);
        expect(form.find('input[name="file"]').attributes('value')).toBe('test');
      });

      it('submits the form when the primary button is clicked', async () => {
        const submitSpy = jest.spyOn(findForm().element, 'submit');

        findGlModal().vm.$emit('primary');
        await waitForPromises();

        expect(submitSpy).toHaveBeenCalled();
      });
    });
  });
});
