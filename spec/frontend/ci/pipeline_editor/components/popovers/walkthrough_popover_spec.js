import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import WalkthroughPopover from '~/ci/pipeline_editor/components/popovers/walkthrough_popover.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.config.ignoredElements = ['gl-emoji'];

describe('WalkthroughPopover component', () => {
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    return extendedWrapper(mountFn(WalkthroughPopover));
  };

  describe('CTA button clicked', () => {
    beforeEach(async () => {
      wrapper = createComponent(mount);
      await wrapper.findByTestId('ctaBtn').trigger('click');
    });

    it('emits "walkthrough-popover-cta-clicked" event', () => {
      expect(wrapper.emitted()['walkthrough-popover-cta-clicked']).toHaveLength(1);
    });
  });
});
