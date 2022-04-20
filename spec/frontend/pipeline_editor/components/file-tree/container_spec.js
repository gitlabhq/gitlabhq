import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import PipelineEditorFileTreeContainer from '~/pipeline_editor/components/file_tree/container.vue';
import PipelineEditorFileTreeItem from '~/pipeline_editor/components/file_tree/file_item.vue';
import { MOCK_DEFAULT_CI_FILE } from './constants';

describe('Pipeline editor file nav', () => {
  let wrapper;

  const createComponent = ({ stubs } = {}) => {
    wrapper = shallowMount(PipelineEditorFileTreeContainer, {
      provide: {
        ciConfigPath: MOCK_DEFAULT_CI_FILE,
      },
      stubs,
    });
  };

  const findTip = () => wrapper.findComponent(GlAlert);
  const fileTreeItem = () => wrapper.findComponent(PipelineEditorFileTreeItem);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlAlert } });
    });

    it('renders config file as a file item', () => {
      expect(fileTreeItem().exists()).toBe(true);
      expect(fileTreeItem().props('fileName')).toBe(MOCK_DEFAULT_CI_FILE);
    });

    it('renders tip', () => {
      expect(findTip().exists()).toBe(true);
    });
  });

  describe('alert tip', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlAlert } });
    });

    it('can dismiss the tip', async () => {
      expect(findTip().exists()).toBe(true);

      findTip().vm.$emit('dismiss');
      await nextTick();

      expect(findTip().exists()).toBe(false);
    });
  });
});
