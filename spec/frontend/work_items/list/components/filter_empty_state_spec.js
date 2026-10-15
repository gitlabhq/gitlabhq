import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FilterEmptyState from '~/work_items/list/components/filter_empty_state.vue';

describe('FilterEmptyState component', () => {
  let wrapper;

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = () => {
    wrapper = shallowMount(FilterEmptyState);
  };

  it('shows empty state', () => {
    mountComponent();

    expect(findGlEmptyState().props()).toMatchObject({
      description: 'To widen your search, change or remove filters above.',
      title: 'No results found',
    });
  });
});
