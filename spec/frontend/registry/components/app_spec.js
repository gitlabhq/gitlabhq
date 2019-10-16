import { mount } from '@vue/test-utils';
import registry from '~/registry/components/app.vue';
import { TEST_HOST } from '../../helpers/test_constants';
import { reposServerResponse, parsedReposServerResponse } from '../mock_data';

describe('Registry List', () => {
  let wrapper;

  const findCollapsibleContainer = w => w.findAll({ name: 'CollapsibeContainerRegisty' });
  const findNoContainerImagesText = w => w.find('.js-no-container-images-text');
  const findNotLoggedInToRegistryText = w => w.find('.js-not-logged-in-to-registry-text');
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

  const methods = {
    setMainEndpoint,
    fetchRepos,
  };

  beforeEach(() => {
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

    it('should render empty message', () => {
      const noContainerImagesText = findNoContainerImagesText(localWrapper);
      expect(noContainerImagesText.text()).toEqual(
        'With the Container Registry, every project can have its own space to store its Docker images. More Information',
      );
    });

    it('should render login help text', () => {
      const notLoggedInToRegistryText = findNotLoggedInToRegistryText(localWrapper);
      expect(notLoggedInToRegistryText.text()).toEqual(
        'If you are not already logged in, you need to authenticate to the Container Registry by using your GitLab username and password. If you have Two-Factor Authentication enabled, use a Personal Access Token instead of a password.',
      );
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
});
