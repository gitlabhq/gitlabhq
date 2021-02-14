import { GlButton, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import SubmitChangesError from '~/static_site_editor/components/submit_changes_error.vue';

import { submitChangesError as error } from '../mock_data';

describe('Submit Changes Error', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(SubmitChangesError, {
      propsData: {
        ...propsData,
      },
      stubs: {
        GlAlert,
      },
    });
  };

  const findRetryButton = () => wrapper.find(GlButton);
  const findAlert = () => wrapper.find(GlAlert);

  beforeEach(() => {
    buildWrapper({ error });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders error message', () => {
    expect(findAlert().text()).toContain(error);
  });

  it('emits dismiss event when alert emits dismiss event', () => {
    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismiss')).toHaveLength(1);
  });

  it('emits retry event when retry button is clicked', () => {
    findRetryButton().vm.$emit('click');

    expect(wrapper.emitted('retry')).toHaveLength(1);
  });
});
