import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { GlEmptyState } from '../../stubs';
import groupEmptyState from '~/registry/explorer/components/list_page/group_empty_state.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Registry Group Empty state', () => {
  let wrapper;
  const config = {
    noContainersImage: 'foo',
    helpPagePath: 'baz',
  };

  beforeEach(() => {
    wrapper = shallowMount(groupEmptyState, {
      localVue,
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
      provide() {
        return { config };
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
