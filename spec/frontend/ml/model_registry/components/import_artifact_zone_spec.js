import { GlAlert, GlFormInputGroup, GlProgressBar } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { uploadModel } from '~/ml/model_registry/services/upload_model';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

jest.mock('~/alert');
jest.mock('~/ml/model_registry/services/upload_model', () => ({
  uploadModel: jest.fn(() => Promise.resolve()),
}));

describe('ImportArtifactZone', () => {
  let wrapper;

  const provide = { maxAllowedFileSize: 99999 };

  const file = { name: 'file.txt', size: 1024 };
  const initialProps = {
    path: 'some/path',
  };
  const formattedFileSizeDiv = () => wrapper.findByTestId('formatted-file-size');
  const formattedProgress = () => wrapper.findByTestId('formatted-progress');
  const fileNameDiv = () => wrapper.findByTestId('file-name');
  const zone = () => wrapper.findComponent(UploadDropzone);
  const progressBar = () => wrapper.findComponent(GlProgressBar);
  const emulateFileDrop = () => zone().vm.$emit('change', file);
  const subfolderInput = () => wrapper.findByTestId('subfolderId');
  const subfolderLabel = () => wrapper.findByTestId('subfolderLabel');
  const subfolderGroup = () => wrapper.findByTestId('subfolderGroup');
  const alert = () => wrapper.findComponent(GlAlert);

  describe('Successful upload', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
        },
        provide,
      });
    });

    it('displays the formatted file size', async () => {
      await emulateFileDrop();
      expect(formattedFileSizeDiv().text()).toBe('1.00 KiB');
    });

    it('displays the formatted file name', async () => {
      await emulateFileDrop();
      expect(fileNameDiv().text()).toBe('file.txt');
    });

    it('displays the progress bar', async () => {
      uploadModel.mockImplementation(({ onUploadProgress }) => {
        onUploadProgress({ total: 10, loaded: 3 });
        return Promise.resolve();
      });
      await emulateFileDrop();

      expect(progressBar().exists()).toBe(true);
      expect(formattedProgress().text()).toBe('3 B / 10 B');
    });

    it('resets the file and loading state', async () => {
      await emulateFileDrop();

      await waitForPromises();
      expect(progressBar().exists()).toBe(false);
      expect(formattedFileSizeDiv().exists()).toBe(false);
      expect(fileNameDiv().exists()).toBe(false);
    });

    it('submits the request', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(uploadModel).toHaveBeenCalledWith({
        file: {
          name: 'file.txt',
          size: 1024,
        },
        importPath: 'some/path',
        subfolder: '',
        maxAllowedFileSize: 99999,
        onUploadProgress: expect.any(Function),
      });
    });

    it('emits a change event on success', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(wrapper.emitted('change')).toStrictEqual([[]]);
    });

    it('shows and success alert', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(alert().text()).toBe('Uploaded files successfully');
      expect(alert().props().variant).toBe('success');
    });
  });

  describe('Subfolder path', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
        },
        provide,
        stubs: {
          GlFormInputGroup,
        },
      });
    });

    it('displays the subfolder input', () => {
      expect(subfolderInput().exists()).toBe(true);
    });

    it('displays the subfolder label', () => {
      expect(subfolderLabel().text()).toBe('Subfolder (optional)');
    });

    it('displays the subfolder description initial state', async () => {
      await subfolderInput().vm.$emit('input', 'subfolder');
      await nextTick();
      expect(subfolderGroup().attributes('description')).toBe(
        'Enter a subfolder name to organize your artifacts.',
      );
      expect(subfolderGroup().attributes('state')).toBe('true');
    });

    it.each(['sub folder', 'subfolder ', ' subfolder', ' sub folder', '   subfolder '])(
      'displays the subfolder invalid instead of description',
      async (subfolder) => {
        await subfolderInput().vm.$emit('input', subfolder);
        await nextTick();
        expect(subfolderInput().attributes('value')).toBe(subfolder);
        expect(subfolderGroup().attributes('description')).toBe('');
        expect(subfolderGroup().attributes('invalid-feedback')).toBe(
          'Subfolder cannot contain spaces',
        );
        expect(subfolderGroup().attributes('state')).toBe(undefined);
      },
    );

    it.each(['subfolder', 'subfolder/sub2', 'subfolder/', 'sub_folder'])(
      'displays the subfolder in a valid state',
      async (subfolder) => {
        await subfolderInput().vm.$emit('input', subfolder);
        await nextTick();
        expect(subfolderInput().attributes('value')).toBe(subfolder);
        expect(subfolderGroup().attributes('description')).toBe(
          'Enter a subfolder name to organize your artifacts.',
        );
        expect(subfolderGroup().attributes('state')).toBe('true');
      },
    );

    it('displays the placeholder in the subfolder input', () => {
      expect(subfolderInput().attributes('placeholder')).toBe('folder name');
    });

    it('displays the formatted file name', async () => {
      await subfolderInput().vm.$emit('input', 'action');
      await emulateFileDrop();
      expect(fileNameDiv().text()).toBe('action/file.txt');
    });

    it('submits the request with a path', async () => {
      await subfolderInput().vm.$emit('input', 'action');
      await emulateFileDrop();
      await waitForPromises();

      expect(uploadModel).toHaveBeenCalledWith({
        file: {
          name: 'file.txt',
          size: 1024,
        },
        importPath: 'some/path',
        subfolder: 'action',
        maxAllowedFileSize: 99999,
        onUploadProgress: expect.any(Function),
      });
    });
  });

  describe('Failed uploads', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
        },
        provide,
      });
    });

    it('displays an error on failure', async () => {
      uploadModel.mockRejectedValue('File is too big.');

      await emulateFileDrop();
      await waitForPromises();

      expect(alert().text()).toBe('File is too big.');
      expect(alert().props().variant).toBe('danger');
    });

    it('resets the state on failure', async () => {
      uploadModel.mockRejectedValue('Internal server error.');

      await emulateFileDrop();
      await waitForPromises();
      expect(progressBar().exists()).toBe(false);
      expect(formattedFileSizeDiv().exists()).toBe(false);
      expect(fileNameDiv().exists()).toBe(false);
    });
  });

  describe('when submit-on-load is false', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
          submitOnSelect: false,
        },
        provide,
      });
    });

    it('does not submit the request', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(uploadModel).not.toHaveBeenCalled();
      expect(progressBar().exists()).toBe(false);
    });
  });

  describe('when path is empty', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
          path: null,
        },
        provide,
      });
    });

    it('does not submit the request', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(uploadModel).not.toHaveBeenCalled();
      expect(progressBar().exists()).toBe(false);
    });
  });
});
