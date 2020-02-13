import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { GlEmptyState } from '../stubs';
import projectEmptyState from '~/registry/explorer/components/project_empty_state.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Registry Project Empty state', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = new Vuex.Store({
      state: {
        config: {
          repositoryUrl: 'foo',
          registryHostUrlWithPort: 'bar',
          helpPagePath: 'baz',
          twoFactorAuthHelpLink: 'barBaz',
          personalAccessTokensHelpLink: 'fooBaz',
          noContainersImage: 'bazFoo',
        },
      },
    });
    wrapper = shallowMount(projectEmptyState, {
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
