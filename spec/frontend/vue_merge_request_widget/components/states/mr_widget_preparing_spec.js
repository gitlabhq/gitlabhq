import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';

import Preparing from '~/vue_merge_request_widget/components/states/mr_widget_preparing.vue';
import { MR_WIDGET_PREPARING_ASYNCHRONOUSLY } from '~/vue_merge_request_widget/i18n';

function createComponent() {
  return shallowMount(Preparing);
}

function findSpinnerIcon(wrapper) {
  return wrapper.findComponent(GlLoadingIcon);
}

describe('Preparing', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('should render a spinner', () => {
    expect(findSpinnerIcon(wrapper).exists()).toBe(true);
  });

  it('should render the correct text', () => {
    expect(wrapper.text()).toBe(MR_WIDGET_PREPARING_ASYNCHRONOUSLY);
  });
});
