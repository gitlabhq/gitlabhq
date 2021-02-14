import { GlSprintf } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import projectEmptyState from '~/registry/explorer/components/list_page/project_empty_state.vue';
import { dockerCommands } from '../../mock_data';
import { GlEmptyState } from '../../stubs';

const localVue = createLocalVue();
localVue.use(Vuex);

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
      localVue,
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('to match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
