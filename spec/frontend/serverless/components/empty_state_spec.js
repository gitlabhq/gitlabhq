import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyStateComponent from '~/serverless/components/empty_state.vue';
import { createStore } from '~/serverless/store';

describe('EmptyStateComponent', () => {
  let wrapper;

  beforeEach(() => {
    const store = createStore({
      clustersPath: '/clusters',
      helpPath: '/help',
      emptyImagePath: '/image.svg',
    });
    wrapper = shallowMount(EmptyStateComponent, { store, stubs: { GlEmptyState, GlSprintf } });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render content', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });
});
