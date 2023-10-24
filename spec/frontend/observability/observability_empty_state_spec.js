import { GlButton, GlEmptyState } from '@gitlab/ui';
import ObservabilityEmptyState from '~/observability/components/observability_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ObservabilityEmptyState', () => {
  let wrapper;

  const findEnableButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = shallowMountExtended(ObservabilityEmptyState);
  });

  it('passes the correct title', () => {
    expect(wrapper.findComponent(GlEmptyState).props('title')).toBe(
      'Get started with GitLab Observability',
    );
  });

  it('displays the correct description', () => {
    const description = wrapper.find('span').text();
    expect(description).toBe('Monitor your applications with GitLab Observability.');
  });

  it('displays the enable button', () => {
    const enableButton = findEnableButton();
    expect(enableButton.exists()).toBe(true);
    expect(enableButton.text()).toBe('Enable');
  });

  it('emits enable-tracing when enable button is clicked', () => {
    findEnableButton().vm.$emit('click');

    expect(wrapper.emitted('enable-observability')).toHaveLength(1);
  });
});
