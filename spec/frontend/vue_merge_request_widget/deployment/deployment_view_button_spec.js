import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment/deployment_view_button.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';
import { deploymentMockData } from './deployment_mock_data';

const appButtonText = {
  text: 'View app',
  tooltip: 'View the latest successful deployment to this environment',
};

describe('Deployment View App button', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = mountExtended(DeploymentViewButton, {
      ...options,
    });
  };

  beforeEach(() => {
    createComponent({
      propsData: {
        deployment: deploymentMockData,
        appButtonText,
      },
    });
  });

  const findReviewAppLink = () => wrapper.findComponent(ReviewAppLink);
  const findMrWidgetDeploymentDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDeployUrlMenuItems = () => wrapper.findAllComponents(GlLink);

  describe('text', () => {
    it('renders text as passed', () => {
      expect(findReviewAppLink().props().display.text).toBe(appButtonText.text);
    });
  });

  describe('without changes', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: { ...deploymentMockData, changes: null },
          appButtonText,
        },
      });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(findMrWidgetDeploymentDropdown().exists()).toBe(false);
    });
  });

  describe('with a single change', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: { ...deploymentMockData, changes: [deploymentMockData.changes[0]] },
          appButtonText,
        },
      });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(findMrWidgetDeploymentDropdown().exists()).toBe(false);
    });

    it('renders the link to the review app linked to to the first change', () => {
      const expectedUrl = deploymentMockData.changes[0].external_url;

      expect(findReviewAppLink().attributes('href')).toBe(expectedUrl);
    });
  });

  describe('with multiple changes', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: deploymentMockData,
          appButtonText,
        },
      });
    });

    it('renders the link to the review app with dropdown', () => {
      const dropdown = findMrWidgetDeploymentDropdown();
      const thirdChangeUrl = deploymentMockData.changes[2].external_url;

      expect(dropdown.exists()).toBe(true);

      const links = dropdown.findAll('a');

      expect(links.length).toBe(3);
      expect(links.at(2).attributes('href')).toBe(thirdChangeUrl);
    });

    it('renders all the links to the review apps', () => {
      const allUrls = findDeployUrlMenuItems().wrappers;
      const expectedUrls = deploymentMockData.changes.map((change) => change.external_url);

      expectedUrls.forEach((expectedUrl, idx) => {
        const deployUrl = allUrls[idx];

        expect(deployUrl.attributes('href')).toBe(expectedUrl);
      });
    });
  });
});
