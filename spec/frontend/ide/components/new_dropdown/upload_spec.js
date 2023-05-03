import { mount } from '@vue/test-utils';
import Upload from '~/ide/components/new_dropdown/upload.vue';
import waitForPromises from 'helpers/wait_for_promises';

describe('new dropdown upload', () => {
  let wrapper;

  function createComponent() {
    wrapper = mount(Upload, {
      propsData: {
        path: '',
      },
    });
  }

  const uploadFile = (file) => {
    const input = wrapper.find('input[type="file"]');
    Object.defineProperty(input.element, 'files', { value: [file] });
    input.trigger('change', file);
  };

  const waitForFileToLoad = async () => {
    await waitForPromises();
    return waitForPromises();
  };

  beforeEach(() => {
    createComponent();
  });

  describe('readFile', () => {
    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsDataURL').mockImplementation(() => {});
    });

    it('calls readAsDataURL for all files', () => {
      const file = {
        type: 'images/png',
      };

      uploadFile(file);

      expect(FileReader.prototype.readAsDataURL).toHaveBeenCalledWith(file);
    });
  });

  describe('createFile', () => {
    const textFile = new File(['plain text'], 'textFile', { type: 'test/mime-text' });
    const binaryFile = new File(['😺'], 'binaryFile', { type: 'test/mime-binary' });

    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsText');
    });

    it('calls readAsText and creates file in plain text (without encoding) if the file content is plain text', async () => {
      uploadFile(textFile);

      // Text file has an additional load, so need to wait twice
      await waitForFileToLoad();
      await waitForFileToLoad();

      expect(FileReader.prototype.readAsText).toHaveBeenCalledWith(textFile);
      expect(wrapper.emitted('create')[0]).toStrictEqual([
        {
          name: textFile.name,
          type: 'blob',
          content: 'plain text',
          rawPath: '',
          mimeType: 'test/mime-text',
        },
      ]);
    });

    it('creates a blob URL for the content if binary', async () => {
      uploadFile(binaryFile);

      await waitForFileToLoad();

      expect(FileReader.prototype.readAsText).not.toHaveBeenCalled();

      expect(wrapper.emitted('create')[0]).toStrictEqual([
        {
          name: binaryFile.name,
          type: 'blob',
          content: 'ðº', // '😺'
          rawPath: 'blob:https://gitlab.com/048c7ac1-98de-4a37-ab1b-0206d0ea7e1b',
          mimeType: 'test/mime-binary',
        },
      ]);
    });
  });
});
