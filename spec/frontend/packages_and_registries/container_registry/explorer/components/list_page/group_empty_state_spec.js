import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import groupEmptyState from '~/packages_and_registries/container_registry/explorer/components/list_page/group_empty_state.vue';
import { GlEmptyState } from '../../stubs';

Vue.use(Vuex);

describe('Registry Group Empty state', () => {
  let wrapper;
  const config = {
    noContainersImage: 'foo',
  };

  beforeEach(() => {
    wrapper = shallowMount(groupEmptyState, {
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
      provide() {
        return { config };
      },
    });
  });

  it('to match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
