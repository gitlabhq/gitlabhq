import { shallowMount } from '@vue/test-utils';
import archivedComponent from '~/vue_merge_request_widget/components/states/mr_widget_archived.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

describe('MRWidgetArchived', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(archivedComponent, { propsData: { mr: {} } });
  });

  it('renders error icon', () => {
    expect(wrapper.findComponent(StateContainer).exists()).toBe(true);
    expect(wrapper.findComponent(StateContainer).props().status).toBe('failed');
  });

  it('renders information about merging', () => {
    const message = wrapper.findComponent(BoldText).props('message');
    expect(message).toContain('Merge unavailable:');
    expect(message).toContain('merge requests are read-only on archived projects.');
  });
});
