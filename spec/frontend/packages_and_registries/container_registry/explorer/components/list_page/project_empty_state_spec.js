import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import projectEmptyState from '~/packages_and_registries/container_registry/explorer/components/list_page/project_empty_state.vue';
import { dockerCommands } from '../../mock_data';
import { GlEmptyState } from '../../stubs';

Vue.use(Vuex);

describe('Registry Project Empty state', () => {
  let wrapper;
  const config = {
    repositoryUrl: 'foo',
    registryHostUrlWithPort: 'bar',
    helpPagePath: 'baz',
    twoFactorAuthHelpLink: 'barBaz',
    personalAccessTokensHelpLink: 'fooBaz',
    noContainersImage: 'bazFoo',
  };

  beforeEach(() => {
    wrapper = shallowMount(projectEmptyState, {
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
      provide() {
        return {
          config,
          ...dockerCommands,
        };
      },
    });
  });

  it('to match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
