import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import WalkthroughPopover from '~/ci/pipeline_editor/components/popovers/walkthrough_popover.vue';

describe('WalkthroughPopover component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(WalkthroughPopover, {
      components: {
        GlEmoji: { template: '<img/>' },
      },
    });
  };

  describe('CTA button clicked', () => {
    it('emits "walkthrough-popover-cta-clicked" event', () => {
      createComponent(shallowMount);
      wrapper.findComponent(GlButton).vm.$emit('click');

      expect(wrapper.emitted()['walkthrough-popover-cta-clicked']).toHaveLength(1);
    });
  });
});
