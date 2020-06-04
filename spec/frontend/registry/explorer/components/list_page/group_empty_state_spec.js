import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { GlEmptyState } from '../../stubs';
import groupEmptyState from '~/registry/explorer/components/list_page/group_empty_state.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Registry Group Empty state', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = new Vuex.Store({
      state: {
        config: {
          noContainersImage: 'foo',
          helpPagePath: 'baz',
        },
      },
    });
    wrapper = shallowMount(groupEmptyState, {
      localVue,
      store,
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('to match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
