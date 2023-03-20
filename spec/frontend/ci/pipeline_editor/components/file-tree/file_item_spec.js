import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import PipelineEditorFileTreeItem from '~/ci/pipeline_editor/components/file_tree/file_item.vue';
import { mockIncludesWithBlob, mockDefaultIncludes } from '../../mock_data';

describe('Pipeline editor file nav', () => {
  let wrapper;

  const createComponent = ({ file = mockDefaultIncludes } = {}) => {
    wrapper = shallowMount(PipelineEditorFileTreeItem, {
      propsData: {
        file,
      },
    });
  };

  const fileIcon = () => wrapper.findComponent(FileIcon);
  const link = () => wrapper.findComponent(GlLink);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders file icon', () => {
      expect(fileIcon().exists()).toBe(true);
    });

    it('renders file name', () => {
      expect(wrapper.text()).toBe(mockDefaultIncludes.location);
    });

    it('links to raw path by default', () => {
      expect(link().attributes('href')).toBe(mockDefaultIncludes.raw);
    });
  });

  describe('when file has blob link', () => {
    beforeEach(() => {
      createComponent({ file: mockIncludesWithBlob });
    });

    it('links to blob path', () => {
      expect(link().attributes('href')).toBe(mockIncludesWithBlob.blob);
    });
  });
});
