import { GlDropdown, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment/deployment_view_button.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
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
  const findMrWigdetDeploymentDropdown = () => wrapper.findComponent(GlDropdown);
  const findMrWigdetDeploymentDropdownIcon = () =>
    wrapper.findByTestId('mr-wigdet-deployment-dropdown-icon');
  const findDeployUrlMenuItems = () => wrapper.findAllComponents(GlLink);
  const findCopyButton = () => wrapper.findComponent(ModalCopyButton);

  describe('text', () => {
    it('renders text as passed', () => {
      expect(findReviewAppLink().props().display.text).toBe(appButtonText.text);
    });
  });

  describe('without changes', () => {
    let deployment;

    beforeEach(() => {
      deployment = { ...deploymentMockData, changes: null };
    });

    describe('with safe url', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            deployment,
            appButtonText,
          },
        });
      });

      it('renders the link to the review app without dropdown', () => {
        expect(findMrWigdetDeploymentDropdown().exists()).toBe(false);
        expect(findReviewAppLink().attributes('href')).toBe(deployment.external_url);
      });
    });

    describe('without safe URL', () => {
      beforeEach(() => {
        deployment = { ...deployment, external_url: 'postgres://example' };
        createComponent({
          propsData: {
            deployment,
            appButtonText,
          },
        });
      });

      it('renders the link as a copy button', () => {
        expect(findMrWigdetDeploymentDropdown().exists()).toBe(false);
        expect(findCopyButton().props('text')).toBe(deployment.external_url);
      });
    });
  });

  describe('with a single change', () => {
    let deployment;
    let change;

    beforeEach(() => {
      [change] = deploymentMockData.changes;
      deployment = { ...deploymentMockData, changes: [change] };
    });

    describe('with safe URL', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            deployment,
            appButtonText,
          },
        });
      });

      it('renders the link to the review app without dropdown', () => {
        expect(findMrWigdetDeploymentDropdown().exists()).toBe(false);
        expect(findMrWigdetDeploymentDropdownIcon().exists()).toBe(false);
      });

      it('renders the link to the review app linked to to the first change', () => {
        const expectedUrl = deploymentMockData.changes[0].external_url;

        expect(findReviewAppLink().attributes('href')).toBe(expectedUrl);
      });
    });

    describe('with unsafe URL', () => {
      beforeEach(() => {
        change = { ...change, external_url: 'postgres://example' };
        deployment = { ...deployment, changes: [change] };
        createComponent({
          propsData: {
            deployment,
            appButtonText,
          },
        });
      });

      it('renders the link as a copy button', () => {
        expect(findMrWigdetDeploymentDropdown().exists()).toBe(false);
        expect(findCopyButton().props('text')).toBe(change.external_url);
      });
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
      expect(findMrWigdetDeploymentDropdown().exists()).toBe(true);
      expect(findMrWigdetDeploymentDropdownIcon().exists()).toBe(true);
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
