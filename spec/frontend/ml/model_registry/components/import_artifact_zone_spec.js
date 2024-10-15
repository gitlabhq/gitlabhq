import { GlAlert, GlFormInputGroup } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
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
  const anotherFile = { name: 'another file.txt', size: 10 };
  const validFiles = [file, anotherFile];
  const initialProps = {
    path: 'some/path',
  };
  const formattedFileSizeDiv = (ix = 0) => wrapper.findByTestId(`formatted-file-size-${ix}`);
  const formattedProgress = (ix = 0) => wrapper.findByTestId(`formatted-progress-${ix}`);
  const fileNameDiv = (ix = 0) => wrapper.findByTestId(`file-name-${ix}`);
  const zone = () => wrapper.findComponent(UploadDropzone);
  const progressBar = (ix = 0) => wrapper.findByTestId(`progress-${ix}`);
  const uploadFeedback = (ix = 0) => wrapper.findByTestId(`fb-${ix}`);
  const subfolderInput = () => wrapper.findByTestId('subfolderId');
  const subfolderLabel = () => wrapper.findByTestId('subfolderLabel');
  const subfolderLabelOptional = () => wrapper.findByTestId('subfolderLabelOptional');
  const subfolderGroup = () => wrapper.findByTestId('subfolderGroup');
  const alert = () => wrapper.findComponent(GlAlert);
  const cancelButton = (ix = 0) => wrapper.findByTestId(`cancel-button-${ix}`);
  const clearButton = () => wrapper.findByTestId(`clear-button`);

  const emulateFileDrop = (files = validFiles) => zone().vm.$emit('change', files);

  describe('Successful upload', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
        },
        provide,
      });
    });

    it('displays the formatted file name', async () => {
      await emulateFileDrop();

      expect(fileNameDiv().text()).toBe('file.txt');
    });

    it('displays initial progress processing', async () => {
      await emulateFileDrop();

      expect(formattedProgress().text()).toBe('0 B / 1.00 KiB');
    });

    it('displays the progress', async () => {
      uploadModel.mockImplementation(({ onUploadProgress }) => {
        onUploadProgress({ loaded: 3 });
        return Promise.resolve();
      });
      await emulateFileDrop();

      expect(progressBar().exists()).toBe(true);
      expect(formattedProgress().text()).toBe('3 B / 1.00 KiB');
    });

    it('displays the cancel button', async () => {
      uploadModel.mockImplementation(({ onUploadProgress }) => {
        onUploadProgress({ loaded: 3 });
        return Promise.resolve();
      });
      await emulateFileDrop();

      expect(cancelButton().exists()).toBe(true);
    });

    it('keeps the loaded table', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(progressBar().exists()).toBe(true);
      expect(formattedFileSizeDiv().text()).toBe('1.00 KiB');
      expect(fileNameDiv().exists()).toBe(true);
      expect(cancelButton().exists()).toBe(false);
      expect(clearButton().exists()).toBe(true);
    });

    it('clears the loaded table', async () => {
      await emulateFileDrop();
      await waitForPromises();

      await clearButton().vm.$emit('click');

      expect(progressBar().exists()).toBe(false);
      expect(formattedFileSizeDiv().exists()).toBe(false);
      expect(fileNameDiv().exists()).toBe(false);
      expect(cancelButton().exists()).toBe(false);
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
        cancelToken: expect.any(Object),
      });
    });

    it('emits a change event on success', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(wrapper.emitted('change')).toStrictEqual([[]]);
    });

    it('does not show any alert initially', async () => {
      await emulateFileDrop();

      expect(alert().exists()).toBe(false);
    });

    it('shows success alert', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(alert().text()).toBe('Artifacts uploaded successfully.');
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
      expect(subfolderLabel().text()).toBe('Subfolder');
    });

    it('displays the subfolder as optional', () => {
      expect(subfolderLabelOptional().text()).toBe('(Optional)');
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
        cancelToken: expect.any(Object),
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

    it('displays an error on some failure', async () => {
      uploadModel.mockRejectedValueOnce('File is too big.');

      await emulateFileDrop();
      await waitForPromises();

      expect(uploadFeedback().text()).toBe('File is too big.');
      expect(alert().text()).toBe('Artifact uploads completed with errors.');
      expect(alert().props().variant).toBe('warning');
    });

    it('emits an error event on a failure', async () => {
      uploadModel.mockRejectedValueOnce('File is too big.');

      await emulateFileDrop();
      await waitForPromises();

      expect(wrapper.emitted('error')).toStrictEqual([['file.txt: File is too big.']]);
    });

    it('displays an error on failure and cancelation', async () => {
      uploadModel.mockRejectedValueOnce('File is too big.');
      uploadModel.mockRejectedValueOnce('File name is invalid.');

      await emulateFileDrop();
      await waitForPromises();

      expect(uploadFeedback().text()).toBe('File is too big.');
      expect(alert().text()).toBe('All artifact uploads failed or were canceled.');
      expect(alert().props().variant).toBe('danger');
    });

    it('emits an error event on multiple failures', async () => {
      uploadModel.mockRejectedValueOnce('File is too big.');
      uploadModel.mockRejectedValueOnce('File name is invalid.');

      await emulateFileDrop();
      await waitForPromises();

      expect(wrapper.emitted('error')).toStrictEqual([
        ['file.txt: File is too big.'],
        ['file.txt: File is too big. another file.txt: File name is invalid.'],
      ]);
    });

    it('keeps the failed table', async () => {
      uploadModel.mockRejectedValueOnce('Internal server error.');
      await emulateFileDrop();
      await waitForPromises();

      expect(progressBar().exists()).toBe(true);
      expect(formattedFileSizeDiv().exists()).toBe(true);
      expect(fileNameDiv().exists()).toBe(true);
      expect(cancelButton().exists()).toBe(false);
    });

    it('clears the failed table', async () => {
      uploadModel.mockRejectedValueOnce('Internal server error.');
      await emulateFileDrop();
      await waitForPromises();

      await clearButton().vm.$emit('click');

      expect(progressBar().exists()).toBe(false);
      expect(formattedFileSizeDiv().exists()).toBe(false);
      expect(fileNameDiv().exists()).toBe(false);
      expect(cancelButton().exists()).toBe(false);
    });
  });

  describe('Canceled uploads', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(ImportArtifactZone, {
        propsData: {
          ...initialProps,
        },
        provide,
      });
    });

    it('cancels the upload', async () => {
      const cancel = jest.fn();
      jest.spyOn(axios.CancelToken, 'source').mockImplementation(() => ({ cancel, token: {} }));
      uploadModel.mockRejectedValueOnce(new axios.Cancel(wrapper.vm.$options.i18n.cancelMessage));
      await emulateFileDrop();
      cancelButton().vm.$emit('click');
      await waitForPromises();

      expect(cancel).toHaveBeenCalledTimes(1);
      expect(progressBar().exists()).toBe(true);
      expect(uploadFeedback().text()).toBe('User canceled upload.');
      expect(alert().text()).toBe('Artifact uploads completed with errors.');
      expect(alert().props().variant).toBe('warning');
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
    });

    it('displays uploads table', async () => {
      await emulateFileDrop();
      await waitForPromises();

      expect(fileNameDiv().text()).toBe('file.txt');
      expect(formattedFileSizeDiv().text()).toBe('1.00 KiB');
      expect(fileNameDiv().text()).toBe('file.txt');
      expect(cancelButton().exists()).toBe(true);
    });

    it('cancels one upload', async () => {
      await emulateFileDrop();
      await cancelButton().vm.$emit('click');

      expect(progressBar().exists()).toBe(true);
      expect(uploadFeedback().text()).toBe('User canceled upload.');
    });

    it('cancels all upload', async () => {
      await emulateFileDrop();
      await cancelButton(0).vm.$emit('click');
      await cancelButton(1).vm.$emit('click');

      expect(progressBar().exists()).toBe(true);
      expect(uploadFeedback().text()).toBe('User canceled upload.');
      expect(alert().text()).toBe('All artifact uploads failed or were canceled.');
      expect(alert().props().variant).toBe('danger');
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
    });
  });
});
