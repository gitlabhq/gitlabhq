import registry from '~/registry/components/app.vue';
import { mount } from '@vue/test-utils';
import { TEST_HOST } from '../../helpers/test_constants';
import { reposServerResponse, parsedReposServerResponse } from '../mock_data';

describe('Registry List', () => {
  let wrapper;

  const findCollapsibleContainer = w => w.findAll({ name: 'CollapsibeContainerRegisty' });
  const findNoContainerImagesText = w => w.find('.js-no-container-images-text');
  const findSpinner = w => w.find('.gl-spinner');
  const findCharacterErrorText = w => w.find('.js-character-error-text');

  const propsData = {
    endpoint: `${TEST_HOST}/foo`,
    helpPagePath: 'foo',
    noContainersImage: 'foo',
    containersErrorImage: 'foo',
    repositoryUrl: 'foo',
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
