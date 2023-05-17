import { nextTick } from 'vue';
import { GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FileTreePopover from '~/ci/pipeline_editor/components/popovers/file_tree_popover.vue';
import { FILE_TREE_POPOVER_DISMISSED_KEY } from '~/ci/pipeline_editor/constants';
import { mockIncludesHelpPagePath } from '../../mock_data';

describe('FileTreePopover component', () => {
  let wrapper;

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLink = () => findPopover().findComponent(GlLink);

  const createComponent = ({ stubs } = {}) => {
    wrapper = shallowMount(FileTreePopover, {
      provide: {
        includesHelpPagePath: mockIncludesHelpPagePath,
      },
      stubs,
    });
  };

  afterEach(() => {
    localStorage.clear();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlSprintf } });
    });

    it('renders dismissable popover', async () => {
      expect(findPopover().exists()).toBe(true);

      findPopover().vm.$emit('close-button-clicked');
      await nextTick();

      expect(findPopover().exists()).toBe(false);
    });

    it('renders learn more link', () => {
      expect(findLink().exists()).toBe(true);
      expect(findLink().attributes('href')).toBe(mockIncludesHelpPagePath);
    });
  });

  describe('when popover has already been dismissed before', () => {
    it('does not render popover', () => {
      localStorage.setItem(FILE_TREE_POPOVER_DISMISSED_KEY, 'true');
      createComponent();

      expect(findPopover().exists()).toBe(false);
    });
  });
});
