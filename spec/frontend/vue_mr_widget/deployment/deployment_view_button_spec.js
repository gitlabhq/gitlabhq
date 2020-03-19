import { mount } from '@vue/test-utils';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment/deployment_view_button.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';
import { deploymentMockData } from './deployment_mock_data';

const appButtonText = {
  text: 'View app',
  tooltip: 'View the latest successful deployment to this environment',
};

describe('Deployment View App button', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = mount(DeploymentViewButton, {
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        deployment: deploymentMockData,
        appButtonText,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('text', () => {
    it('renders text as passed', () => {
      expect(wrapper.find(ReviewAppLink).text()).toContain(appButtonText.text);
    });
  });

  describe('without changes', () => {
    beforeEach(() => {
      factory({
        propsData: {
          deployment: { ...deploymentMockData, changes: null },
          appButtonText,
        },
      });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(wrapper.find('.js-mr-wigdet-deployment-dropdown').exists()).toBe(false);
    });
  });

  describe('with a single change', () => {
    beforeEach(() => {
      factory({
        propsData: {
          deployment: { ...deploymentMockData, changes: [deploymentMockData.changes[0]] },
          appButtonText,
        },
      });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(wrapper.find('.js-mr-wigdet-deployment-dropdown').exists()).toBe(false);
    });

    it('renders the link to the review app linked to to the first change', () => {
      const expectedUrl = deploymentMockData.changes[0].external_url;
      const deployUrl = wrapper.find('.js-deploy-url');

      expect(deployUrl.attributes().href).not.toBeNull();
      expect(deployUrl.attributes().href).toEqual(expectedUrl);
    });
  });

  describe('with multiple changes', () => {
    beforeEach(() => {
      factory({
        propsData: {
          deployment: deploymentMockData,
          appButtonText,
        },
      });
    });

    it('renders the link to the review app with dropdown', () => {
      expect(wrapper.find('.js-mr-wigdet-deployment-dropdown').exists()).toBe(true);
    });

    it('renders all the links to the review apps', () => {
      const allUrls = wrapper.findAll('.js-deploy-url-menu-item').wrappers;
      const expectedUrls = deploymentMockData.changes.map(change => change.external_url);

      expectedUrls.forEach((expectedUrl, idx) => {
        const deployUrl = allUrls[idx];

        expect(deployUrl.attributes().href).not.toBeNull();
        expect(deployUrl.attributes().href).toEqual(expectedUrl);
      });
    });
  });
});
