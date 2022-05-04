import { nextTick } from 'vue';
import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FileTreePopover from '~/pipeline_editor/components/popovers/file_tree_popover.vue';
import { FILE_TREE_POPOVER_DISMISSED_KEY } from '~/pipeline_editor/constants';

describe('FileTreePopover component', () => {
  let wrapper;

  const findPopover = () => wrapper.findComponent(GlPopover);

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(FileTreePopover);
  };

  afterEach(() => {
    localStorage.clear();
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(async () => {
      createComponent();
    });

    it('renders dismissable popover', async () => {
      expect(findPopover().exists()).toBe(true);

      findPopover().vm.$emit('close-button-clicked');
      await nextTick();

      expect(findPopover().exists()).toBe(false);
    });
  });

  describe('when popover has already been dismissed before', () => {
    it('does not render popover', async () => {
      localStorage.setItem(FILE_TREE_POPOVER_DISMISSED_KEY, 'true');
      createComponent();

      expect(findPopover().exists()).toBe(false);
    });
  });
});
