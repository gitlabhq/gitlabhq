import { mount, createLocalVue } from '@vue/test-utils';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment/deployment_view_button.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';
import deploymentMockData from './deployment_mock_data';

describe('Deployment View App button', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(DeploymentViewButton), {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        deployment: deploymentMockData,
        isCurrent: true,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('text', () => {
    describe('when app is current', () => {
      it('shows View app', () => {
        expect(wrapper.find(ReviewAppLink).text()).toContain('View app');
      });
    });

    describe('when app is not current', () => {
      beforeEach(() => {
        factory({
          propsData: {
            deployment: deploymentMockData,
            isCurrent: false,
          },
        });
      });

      it('shows View Previous app', () => {
        expect(wrapper.find(ReviewAppLink).text()).toContain('View previous app');
      });
    });
  });

  describe('without changes', () => {
    beforeEach(() => {
      factory({
        propsData: {
          deployment: { ...deploymentMockData, changes: null },
          isCurrent: false,
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
          isCurrent: false,
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
          isCurrent: false,
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
