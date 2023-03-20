import { shallowMount } from '@vue/test-utils';
import CheckingComponent from '~/vue_merge_request_widget/components/states/mr_widget_checking.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';

describe('MRWidgetChecking', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(CheckingComponent, { propsData: { mr: {} } });
  });

  it('renders loading icon', () => {
    expect(wrapper.findComponent(StateContainer).exists()).toBe(true);
    expect(wrapper.findComponent(StateContainer).props().status).toBe('loading');
  });

  it('renders information about merging', () => {
    expect(wrapper.text()).toContain('Checking if merge request can be merged…');
  });
});
