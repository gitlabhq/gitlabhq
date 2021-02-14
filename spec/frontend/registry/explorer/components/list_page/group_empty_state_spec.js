import { GlSprintf } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import groupEmptyState from '~/registry/explorer/components/list_page/group_empty_state.vue';
import { GlEmptyState } from '../../stubs';

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
