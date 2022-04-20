import { shallowMount } from '@vue/test-utils';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import PipelineEditorFileTreeItem from '~/pipeline_editor/components/file_tree/file_item.vue';
import { MOCK_DEFAULT_CI_FILE } from './constants';

describe('Pipeline editor file nav', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineEditorFileTreeItem, {
      propsData: {
        fileName: MOCK_DEFAULT_CI_FILE,
      },
    });
  };

  const fileIcon = () => wrapper.findComponent(FileIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders file icon', () => {
      expect(fileIcon().exists()).toBe(true);
      expect(fileIcon().props('fileName')).toBe(MOCK_DEFAULT_CI_FILE);
    });

    it('renders file name', () => {
      expect(wrapper.text()).toBe(MOCK_DEFAULT_CI_FILE);
    });
  });
});
