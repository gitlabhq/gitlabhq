import { mount } from '@vue/test-utils';
import Upload from '~/ide/components/new_dropdown/upload.vue';

describe('new dropdown upload', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(Upload, {
      propsData: {
        path: '',
      },
    });
  });

  describe('openFile', () => {
    it('calls for each file', () => {
      const files = ['test', 'test2', 'test3'];

      jest.spyOn(wrapper.vm, 'readFile').mockImplementation(() => {});
      jest.spyOn(wrapper.vm.$refs.fileUpload, 'files', 'get').mockReturnValue(files);

      wrapper.vm.openFile();

      expect(wrapper.vm.readFile.mock.calls.length).toBe(3);

      files.forEach((file, i) => {
        expect(wrapper.vm.readFile.mock.calls[i]).toEqual([file]);
      });
    });
  });

  describe('readFile', () => {
    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsDataURL').mockImplementation(() => {});
    });

    it('calls readAsDataURL for all files', () => {
      const file = {
        type: 'images/png',
      };

      wrapper.vm.readFile(file);

      expect(FileReader.prototype.readAsDataURL).toHaveBeenCalledWith(file);
    });
  });

  describe('createFile', () => {
    const textTarget = {
      result: 'base64,cGxhaW4gdGV4dA==',
    };
    const binaryTarget = {
      result: 'base64,8PDw8A==', // ðððð
    };

    const textFile = new File(['plain text'], 'textFile', { type: 'test/mime-text' });
    const binaryFile = new File(['😺'], 'binaryFile', { type: 'test/mime-binary' });

    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsText');
    });

    it('calls readAsText and creates file in plain text (without encoding) if the file content is plain text', async () => {
      const waitForCreate = new Promise((resolve) => {
        wrapper.vm.$on('create', resolve);
      });

      wrapper.vm.createFile(textTarget, textFile);

      expect(FileReader.prototype.readAsText).toHaveBeenCalledWith(textFile);

      await waitForCreate;
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

    it('creates a blob URL for the content if binary', () => {
      wrapper.vm.createFile(binaryTarget, binaryFile);

      expect(FileReader.prototype.readAsText).not.toHaveBeenCalled();

      expect(wrapper.emitted('create')[0]).toStrictEqual([
        {
          name: binaryFile.name,
          type: 'blob',
          content: 'ðððð',
          rawPath: 'blob:https://gitlab.com/048c7ac1-98de-4a37-ab1b-0206d0ea7e1b',
          mimeType: 'test/mime-binary',
        },
      ]);
    });
  });
});
