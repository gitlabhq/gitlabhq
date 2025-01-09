import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlModal } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CsvUploadModal from '~/members/placeholders/components/csv_upload_modal.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/alert');

const MOCK_REASSIGNMENT_CSV_PATH = 'group_members/bulk_reassignment_file';

describe('CsvUploadModal', () => {
  let wrapper;
  let mockAxios;

  const defaultInjectedAttributes = {
    reassignmentCsvPath: MOCK_REASSIGNMENT_CSV_PATH,
  };

  const findDownloadLink = () => wrapper.findByTestId('csv-download-button');
  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findUploadErrorAlert = () => wrapper.findByTestId('upload-error');
  const findGlModal = () => wrapper.findComponent(GlModal);

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
    mockAxios = new MockAdapter(axios);
    wrapper = createComponent();
  });

  afterEach(() => {
    mockAxios.restore();
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
        'Could not upload the file. Check that the file follows the CSV template and try again.',
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

    describe('submitting the data', () => {
      beforeEach(() => {
        jest.spyOn(axios, 'post');
      });

      it('calls the endpoint with the correct data', async () => {
        const uploadDropzone = findUploadDropzone();
        const file = new File(['test'], 'file.csv');

        uploadDropzone.vm.$emit('change', file);
        await waitForPromises();

        findGlModal().vm.$emit('primary');
        await waitForPromises();

        const expectedFormData = new FormData();
        expectedFormData.append('file', file);

        expect(axios.post).toHaveBeenCalledWith(MOCK_REASSIGNMENT_CSV_PATH, expectedFormData);
      });

      describe('when the request succeeds', () => {
        it('displays the message from the response', async () => {
          const mockMessage = 'file is being processed';

          mockAxios
            .onPost(MOCK_REASSIGNMENT_CSV_PATH)
            .reply(HTTP_STATUS_OK, { message: mockMessage });

          findGlModal().vm.$emit('primary');
          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message: mockMessage,
            variant: 'success',
          });
        });
      });

      describe('when the request fails', () => {
        it('displays the message from the response if present', async () => {
          const mockMessage = 'file too large';

          mockAxios
            .onPost(MOCK_REASSIGNMENT_CSV_PATH)
            .reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, { message: mockMessage });

          findGlModal().vm.$emit('primary');
          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message: mockMessage,
          });
        });

        it('display an alert error message', async () => {
          mockAxios
            .onPost(MOCK_REASSIGNMENT_CSV_PATH)
            .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { error: new Error('error uploading CSV') });

          findGlModal().vm.$emit('primary');
          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message: 'Something went wrong while uploading the CSV file.',
          });
        });
      });
    });
  });
});
