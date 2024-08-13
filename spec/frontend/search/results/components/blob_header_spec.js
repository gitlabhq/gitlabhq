import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import BlobHeader from '~/search/results/components/blob_header.vue';

describe('BlobHeader', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(BlobHeader, {
      propsData: {
        ...props,
      },
    });
  };

  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findFileIcon = () => wrapper.findComponent(FileIcon);
  const findProjectPath = () => wrapper.findByTestId('project-path-content');
  const findProjectName = () => wrapper.findByTestId('file-name-content');

  describe('component basics', () => {
    beforeEach(() => {
      createComponent({
        filePath: 'test/file.js',
        projectPath: 'Testjs/Test',
        fileUrl: 'https://gitlab.com/test/file.js',
      });
    });

    it(`renders all parts of header`, () => {
      expect(findClipboardButton().exists()).toBe(true);
      expect(findFileIcon().exists()).toBe(true);
      expect(findProjectPath().exists()).toBe(true);
      expect(findProjectName().exists()).toBe(true);
    });
  });

  describe('limited component', () => {
    beforeEach(() => {
      createComponent({
        filePath: 'test/file.js',
        fileUrl: 'https://gitlab.com/test/file.js',
      });
    });

    it(`renders withough projectPath`, () => {
      expect(findClipboardButton().exists()).toBe(true);
      expect(findFileIcon().exists()).toBe(true);
      expect(findProjectPath().exists()).toBe(false);
      expect(findProjectName().exists()).toBe(true);
    });
  });
});
