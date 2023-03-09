import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Panel from '~/google_cloud/configuration/panel.vue';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';
import GoogleCloudMenu from '~/google_cloud/components/google_cloud_menu.vue';
import ServiceAccountsList from '~/google_cloud/service_accounts/list.vue';
import GcpRegionsList from '~/google_cloud/gcp_regions/list.vue';
import RevokeOauth from '~/google_cloud/components/revoke_oauth.vue';

describe('google_cloud/configuration/panel', () => {
  let wrapper;

  const props = {
    configurationUrl: 'configuration-url',
    deploymentsUrl: 'deployments-url',
    databasesUrl: 'databases-url',
    serviceAccounts: [],
    createServiceAccountUrl: 'create-service-account-url',
    emptyIllustrationUrl: 'empty-illustration-url',
    gcpRegions: [],
    configureGcpRegionsUrl: 'configure-gcp-regions-url',
    revokeOauthUrl: 'revoke-oauth-url',
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(Panel, { propsData: props });
  });

  it('contains incubation banner', () => {
    const target = wrapper.findComponent(IncubationBanner);
    expect(target.exists()).toBe(true);
  });

  it('contains google cloud menu with `configuration` active', () => {
    const target = wrapper.findComponent(GoogleCloudMenu);
    expect(target.exists()).toBe(true);
    expect(target.props('active')).toBe('configuration');
    expect(target.props('configurationUrl')).toBe(props.configurationUrl);
    expect(target.props('deploymentsUrl')).toBe(props.deploymentsUrl);
    expect(target.props('databasesUrl')).toBe(props.databasesUrl);
  });

  it('contains service accounts list', () => {
    const target = wrapper.findComponent(ServiceAccountsList);
    expect(target.exists()).toBe(true);
    expect(target.props('list')).toBe(props.serviceAccounts);
    expect(target.props('createUrl')).toBe(props.createServiceAccountUrl);
    expect(target.props('emptyIllustrationUrl')).toBe(props.emptyIllustrationUrl);
  });

  it('contains gcp regions list', () => {
    const target = wrapper.findComponent(GcpRegionsList);
    expect(target.props('list')).toBe(props.gcpRegions);
    expect(target.props('createUrl')).toBe(props.configureGcpRegionsUrl);
    expect(target.props('emptyIllustrationUrl')).toBe(props.emptyIllustrationUrl);
  });

  it('contains revoke oauth', () => {
    const target = wrapper.findComponent(RevokeOauth);
    expect(target.props('url')).toBe(props.revokeOauthUrl);
  });
});
