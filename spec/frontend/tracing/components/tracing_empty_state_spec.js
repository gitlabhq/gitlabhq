import { GlButton, GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingEmptyState from '~/tracing/components/tracing_empty_state.vue';

describe('TracingEmptyState', () => {
  let wrapper;

  const findEnableButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = shallowMountExtended(TracingEmptyState);
  });

  it('renders the component properly', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('displays the correct title', () => {
    const { title } = wrapper.findComponent(GlEmptyState).props();
    expect(title).toBe('Get started with Tracing');
  });

  it('displays the correct description', () => {
    const description = wrapper.find('span').text();
    expect(description).toBe('Monitor your applications with GitLab Distributed Tracing.');
  });

  it('displays the enable button', () => {
    const enableButton = findEnableButton();
    expect(enableButton.exists()).toBe(true);
    expect(enableButton.text()).toBe('Enable');
  });

  it('emits enable-tracing when enable button is clicked', () => {
    findEnableButton().vm.$emit('click');

    expect(wrapper.emitted('enable-tracing')).toHaveLength(1);
  });
});
