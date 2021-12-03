import { shallowMount } from '@vue/test-utils';
import App from '~/google_cloud/components/app.vue';
import Home from '~/google_cloud/components/home.vue';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import ServiceAccountsForm from '~/google_cloud/components/service_accounts_form.vue';
import GcpError from '~/google_cloud/components/errors/gcp_error.vue';
import NoGcpProjects from '~/google_cloud/components/errors/no_gcp_projects.vue';

const BASE_FEEDBACK_URL =
  'https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/meta/-/issues/new';

describe('google_cloud App component', () => {
  let wrapper;

  const findIncubationBanner = () => wrapper.findComponent(IncubationBanner);
  const findGcpError = () => wrapper.findComponent(GcpError);
  const findNoGcpProjects = () => wrapper.findComponent(NoGcpProjects);
  const findServiceAccountsForm = () => wrapper.findComponent(ServiceAccountsForm);
  const findHome = () => wrapper.findComponent(Home);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('for gcp_error screen', () => {
    beforeEach(() => {
      const propsData = {
        screen: 'gcp_error',
        error: 'mock_gcp_client_error',
      };
      wrapper = shallowMount(App, { propsData });
    });

    it('renders the gcp_error screen', () => {
      expect(findGcpError().exists()).toBe(true);
    });

    it('should contain incubation banner', () => {
      expect(findIncubationBanner().props()).toEqual({
        shareFeedbackUrl: `${BASE_FEEDBACK_URL}?issuable_template=general_feedback`,
        reportBugUrl: `${BASE_FEEDBACK_URL}?issuable_template=report_bug`,
        featureRequestUrl: `${BASE_FEEDBACK_URL}?issuable_template=feature_request`,
      });
    });
  });

  describe('for no_gcp_projects screen', () => {
    beforeEach(() => {
      const propsData = {
        screen: 'no_gcp_projects',
      };
      wrapper = shallowMount(App, { propsData });
    });

    it('renders the no_gcp_projects screen', () => {
      expect(findNoGcpProjects().exists()).toBe(true);
    });

    it('should contain incubation banner', () => {
      expect(findIncubationBanner().props()).toEqual({
        shareFeedbackUrl: `${BASE_FEEDBACK_URL}?issuable_template=general_feedback`,
        reportBugUrl: `${BASE_FEEDBACK_URL}?issuable_template=report_bug`,
        featureRequestUrl: `${BASE_FEEDBACK_URL}?issuable_template=feature_request`,
      });
    });
  });

  describe('for service_accounts_form screen', () => {
    beforeEach(() => {
      const propsData = {
        screen: 'service_accounts_form',
        gcpProjects: [1, 2, 3],
        environments: [4, 5, 6],
        cancelPath: '',
      };
      wrapper = shallowMount(App, { propsData });
    });

    it('renders the service_accounts_form screen', () => {
      expect(findServiceAccountsForm().exists()).toBe(true);
    });

    it('should contain incubation banner', () => {
      expect(findIncubationBanner().props()).toEqual({
        shareFeedbackUrl: `${BASE_FEEDBACK_URL}?issuable_template=general_feedback`,
        reportBugUrl: `${BASE_FEEDBACK_URL}?issuable_template=report_bug`,
        featureRequestUrl: `${BASE_FEEDBACK_URL}?issuable_template=feature_request`,
      });
    });
  });

  describe('for home screen', () => {
    beforeEach(() => {
      const propsData = {
        screen: 'home',
        serviceAccounts: [{}, {}],
        createServiceAccountUrl: '#url-create-service-account',
        emptyIllustrationUrl: '#url-empty-illustration',
      };
      wrapper = shallowMount(App, { propsData });
    });

    it('renders the home screen', () => {
      expect(findHome().exists()).toBe(true);
    });

    it('should contain incubation banner', () => {
      expect(findIncubationBanner().props()).toEqual({
        shareFeedbackUrl: `${BASE_FEEDBACK_URL}?issuable_template=general_feedback`,
        reportBugUrl: `${BASE_FEEDBACK_URL}?issuable_template=report_bug`,
        featureRequestUrl: `${BASE_FEEDBACK_URL}?issuable_template=feature_request`,
      });
    });
  });
});
