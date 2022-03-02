import { shallowMount } from '@vue/test-utils';
import { mapValues } from 'lodash';
import App from '~/google_cloud/components/app.vue';
import Home from '~/google_cloud/components/home.vue';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import ServiceAccountsForm from '~/google_cloud/components/service_accounts_form.vue';
import GcpError from '~/google_cloud/components/errors/gcp_error.vue';
import NoGcpProjects from '~/google_cloud/components/errors/no_gcp_projects.vue';

const BASE_FEEDBACK_URL =
  'https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/meta/-/issues/new';
const SCREEN_COMPONENTS = {
  Home,
  ServiceAccountsForm,
  GcpError,
  NoGcpProjects,
};
const SERVICE_ACCOUNTS_FORM_PROPS = {
  gcpProjects: [1, 2, 3],
  refs: [4, 5, 6],
  cancelPath: '',
};
const HOME_PROPS = {
  serviceAccounts: [{}, {}],
  gcpRegions: [{}, {}],
  createServiceAccountUrl: '#url-create-service-account',
  configureGcpRegionsUrl: '#url-configure-gcp-regions',
  emptyIllustrationUrl: '#url-empty-illustration',
  enableCloudRunUrl: '#url-enable-cloud-run',
  enableCloudStorageUrl: '#enableCloudStorageUrl',
};

describe('google_cloud App component', () => {
  let wrapper;

  const findIncubationBanner = () => wrapper.findComponent(IncubationBanner);

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    screen                     | extraProps                            | componentName
    ${'gcp_error'}             | ${{ error: 'mock_gcp_client_error' }} | ${'GcpError'}
    ${'no_gcp_projects'}       | ${{}}                                 | ${'NoGcpProjects'}
    ${'service_accounts_form'} | ${SERVICE_ACCOUNTS_FORM_PROPS}        | ${'ServiceAccountsForm'}
    ${'home'}                  | ${HOME_PROPS}                         | ${'Home'}
  `('for screen=$screen', ({ screen, extraProps, componentName }) => {
    const component = SCREEN_COMPONENTS[componentName];

    beforeEach(() => {
      wrapper = shallowMount(App, { propsData: { screen, ...extraProps } });
    });

    it(`renders only ${componentName}`, () => {
      const existences = mapValues(SCREEN_COMPONENTS, (x) => wrapper.findComponent(x).exists());

      expect(existences).toEqual({
        ...mapValues(SCREEN_COMPONENTS, () => false),
        [componentName]: true,
      });
    });

    it(`renders the ${componentName} with props`, () => {
      expect(wrapper.findComponent(component).props()).toEqual(extraProps);
    });

    it('renders incubation banner', () => {
      expect(findIncubationBanner().props()).toEqual({
        shareFeedbackUrl: `${BASE_FEEDBACK_URL}?issuable_template=general_feedback`,
        reportBugUrl: `${BASE_FEEDBACK_URL}?issuable_template=report_bug`,
        featureRequestUrl: `${BASE_FEEDBACK_URL}?issuable_template=feature_request`,
      });
    });
  });
});
