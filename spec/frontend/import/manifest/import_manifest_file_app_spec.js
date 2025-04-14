import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK, HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportFromManifestFileApp from '~/import/manifest/import_manifest_file_app.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('Import from Manifest file app', () => {
  let wrapper;
  let mockAxios;

  const defaultProps = {
    backButtonPath: 'projects/new#import_project',
    formPath: 'import/manifest/upload',
    statusImportManifestPath: 'import/manifest/status',
    namespaceId: 1,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ImportFromManifestFileApp, {
      propsData: {
        ...defaultProps,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const findMultiStepForm = () => wrapper.findComponent(MultiStepFormTemplate);
  const findGroupSelect = () => wrapper.findComponent(GroupSelect);
  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findBackButton = () => wrapper.findByTestId('back-button');
  const findNextButton = () => wrapper.findByTestId('next-button');
  const findUploadError = () => wrapper.findByTestId('upload-error');

  it('renders the multi step form correctly', () => {
    expect(findMultiStepForm().props()).toMatchObject({
      currentStep: 3,
      stepsTotal: 3,
    });
  });

  describe('back button', () => {
    it('renders a back button', () => {
      expect(findBackButton().attributes('href')).toBe(defaultProps.backButtonPath);
    });
  });

  describe('next button', () => {
    it('renders a next button', () => {
      expect(findNextButton().text()).toContain('List available repositories');
    });
  });

  it('renders the group select', () => {
    expect(findGroupSelect().exists()).toBe(true);
  });

  describe('manifest upload', () => {
    it('renders the upload dropzone', () => {
      expect(findUploadDropzone().exists()).toBe(true);
    });

    it('accepts XML files for the dropzone', () => {
      const uploadDropzone = findUploadDropzone();
      const isFileValid = uploadDropzone.props('isFileValid');
      expect(isFileValid({ name: 'upload.xml' })).toBe(true);
    });

    it.each(['.pdf', '.jpg', '.html'])('rejects %s file extension', (extension) => {
      const uploadDropzone = findUploadDropzone();
      const isFileValid = uploadDropzone.props('isFileValid');
      expect(isFileValid({ name: `upload${extension}` })).toBe(false);
    });

    describe('submitting the data', () => {
      const file = new File(['test'], 'file.xml');

      beforeEach(() => {
        jest.spyOn(axios, 'post');

        findUploadDropzone().vm.$emit('change', file);
        findGroupSelect().vm.$emit('input', { id: 123 });
      });

      it('calls the endpoint with the correct data', async () => {
        findNextButton().vm.$emit('click');
        await waitForPromises();

        const expectedFormData = new FormData();
        expectedFormData.append('manifest', file);
        expectedFormData.append('group_id', 123);

        expect(axios.post).toHaveBeenCalledWith(defaultProps.formPath, expectedFormData);
      });

      it('displays an error when the manifest file is missing', async () => {
        findUploadDropzone().vm.$emit('change', null);

        findNextButton().vm.$emit('click');
        await waitForPromises();

        expect(findUploadError().exists()).toBe(true);
        expect(findUploadError().text()).toBe('Please upload a manifest file.');
      });

      describe('when the request succeeds', () => {
        it('redirects to the status page', async () => {
          mockAxios.onPost(defaultProps.formPath).reply(HTTP_STATUS_OK, { success: true });

          findNextButton().vm.$emit('click');
          await waitForPromises();

          expect(visitUrl).toHaveBeenCalledWith(defaultProps.statusImportManifestPath);
        });
      });

      describe('when the request fails', () => {
        it('displays an error message', async () => {
          const mockMessage = 'file too large';

          mockAxios
            .onPost(defaultProps.formPath)
            .reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, { errors: [mockMessage] });

          findNextButton().vm.$emit('click');
          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message: mockMessage,
          });
        });
      });
    });
  });
});
