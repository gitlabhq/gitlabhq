import Vue from 'vue';
import { mount } from '@vue/test-utils';
import registry from '~/registry/components/app.vue';
import { TEST_HOST } from '../../helpers/test_constants';
import { reposServerResponse, parsedReposServerResponse } from '../mock_data';

describe('Registry List', () => {
  let wrapper;

  const findCollapsibleContainer = w => w.findAll({ name: 'CollapsibeContainerRegisty' });
  const findProjectEmptyState = w => w.find({ name: 'ProjectEmptyState' });
  const findGroupEmptyState = w => w.find({ name: 'GroupEmptyState' });
  const findSpinner = w => w.find('.gl-spinner');
  const findCharacterErrorText = w => w.find('.js-character-error-text');

  const propsData = {
    endpoint: `${TEST_HOST}/foo`,
    helpPagePath: 'foo',
    noContainersImage: 'foo',
    containersErrorImage: 'foo',
    repositoryUrl: 'foo',
    registryHostUrlWithPort: 'foo',
    personalAccessTokensHelpLink: 'foo',
    twoFactorAuthHelpLink: 'foo',
  };

  const setMainEndpoint = jest.fn();
  const fetchRepos = jest.fn();
  const setIsDeleteDisabled = jest.fn();

  const methods = {
    setMainEndpoint,
    fetchRepos,
    setIsDeleteDisabled,
  };

  beforeEach(() => {
    // This is needed due to console.error called by vue to emit a warning that stop the tests.
    // See https://github.com/vuejs/vue-test-utils/issues/532.
    Vue.config.silent = true;
    wrapper = mount(registry, {
      propsData,
      computed: {
        repos() {
          return parsedReposServerResponse;
        },
      },
      methods,
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
    Vue.config.silent = false;
    wrapper.destroy();
  });

  describe('with data', () => {
    it('should render a list of CollapsibeContainerRegisty', () => {
      const containers = findCollapsibleContainer(wrapper);
      expect(wrapper.vm.repos.length).toEqual(reposServerResponse.length);
      expect(containers.length).toEqual(reposServerResponse.length);
    });
  });

  describe('without data', () => {
    let localWrapper;
    beforeEach(() => {
      localWrapper = mount(registry, {
        propsData,
        computed: {
          repos() {
            return [];
          },
        },
        methods,
      });
    });

    it('should render project empty message', () => {
      const projectEmptyState = findProjectEmptyState(localWrapper);
      expect(projectEmptyState.exists()).toBe(true);
    });
  });

  describe('while loading data', () => {
    let localWrapper;

    beforeEach(() => {
      localWrapper = mount(registry, {
        propsData,
        computed: {
          repos() {
            return [];
          },
          isLoading() {
            return true;
          },
        },
        methods,
      });
    });

    it('should render a loading spinner', () => {
      const spinner = findSpinner(localWrapper);
      expect(spinner.exists()).toBe(true);
    });
  });

  describe('invalid characters in path', () => {
    let localWrapper;

    beforeEach(() => {
      localWrapper = mount(registry, {
        propsData: {
          ...propsData,
          characterError: true,
        },
        computed: {
          repos() {
            return [];
          },
        },
        methods,
      });
    });

    it('should render invalid characters error message', () => {
      const characterErrorText = findCharacterErrorText(localWrapper);
      expect(characterErrorText.text()).toEqual(
        'We are having trouble connecting to Docker, which could be due to an issue with your project name or path. More Information',
      );
    });
  });

  describe('with groupId set', () => {
    const isGroupPage = true;

    beforeEach(() => {
      wrapper = mount(registry, {
        propsData: {
          ...propsData,
          endpoint: null,
          isGroupPage,
        },
        methods,
      });
    });

    it('call the right vuex setters', () => {
      expect(methods.setMainEndpoint).toHaveBeenLastCalledWith(null);
      expect(methods.setIsDeleteDisabled).toHaveBeenLastCalledWith(true);
    });

    it('should render groups empty message', () => {
      const groupEmptyState = findGroupEmptyState(wrapper);
      expect(groupEmptyState.exists()).toBe(true);
    });
  });
});
