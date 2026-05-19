import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SecurityConfigurationProvider from '~/security_configuration/components/security_configuration_provider.vue';
import SecurityConfigurationApp from '~/security_configuration/components/app.vue';
import securityConfigurationQuery from '~/security_configuration/graphql/security_configuration.query.graphql';
import projectMergeRequestsEnabledQuery from '~/security_configuration/graphql/project_merge_requests_enabled.query.graphql';
import * as logger from '~/lib/logger';
import * as sentryBrowserWrapper from '~/sentry/sentry_browser_wrapper';

Vue.use(VueApollo);

jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('SecurityConfigurationProvider', () => {
  let wrapper;
  let mockApollo;

  const projectId = '1';
  const projectFullPath = 'test/project';

  const mockSecurityConfiguration = {
    autoDevopsEnabled: false,
    autoDevopsHelpPagePath: '/help/autodevops',
    autoDevopsPath: '/autodevops',
    canEnableAutoDevops: true,
    containerScanningForRegistryEnabled: false,
    features: [],
    gitlabCiHistoryPath: '/ci/history',
    gitlabCiPresent: true,
    helpPagePath: '/help',
    latestPipelinePath: '/pipelines/latest',
    licenseConfigurationSource: 'gitlab',
    secretDetectionConfigurationPath: '/secret_detection',
    secretPushProtectionAvailable: false,
    secretPushProtectionEnforced: false,
    secretPushProtectionEnabled: false,
    securityTrainingEnabled: false,
    userIsProjectAdmin: true,
    validityChecksAvailable: false,
    validityChecksEnabled: false,
    vulnerabilityArchiveExportPath: '/export',
    vulnerabilityTrainingDocsPath: '/training',
    upgradePath: '/upgrade',
    groupFullPath: 'test',
    canApplyProfiles: true,
    canReadAttributes: true,
    canManageAttributes: false,
    securityScanProfilesLicensed: true,
    groupManageAttributesPath: '/attributes',
  };

  const mockMergeRequestsEnabled = {
    project: {
      id: `gid://gitlab/Project/1`,
      mergeRequestsEnabled: true,
    },
  };

  const createMockApolloProvider = (securityConfigHandler, mergeRequestsHandler) => {
    mockApollo = createMockApollo([
      [securityConfigurationQuery, securityConfigHandler],
      [projectMergeRequestsEnabledQuery, mergeRequestsHandler],
    ]);
    return mockApollo;
  };

  const createComponent = ({
    securityConfigHandler = jest
      .fn()
      .mockResolvedValue({ data: { securityConfiguration: mockSecurityConfiguration } }),
    mergeRequestsHandler = jest.fn().mockResolvedValue({ data: mockMergeRequestsEnabled }),
  } = {}) => {
    wrapper = mountExtended(SecurityConfigurationProvider, {
      apolloProvider: createMockApolloProvider(securityConfigHandler, mergeRequestsHandler),
      provide: {
        projectId,
        projectFullPath,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findApp = () => wrapper.findComponent(SecurityConfigurationApp);

  describe('on mount', () => {
    it('shows loading state initially', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findApp().exists()).toBe(false);
    });
  });

  describe('when query is successful', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('hides loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders SecurityConfigurationApp', () => {
      expect(findApp().exists()).toBe(true);
    });

    it('passes correct props to SecurityConfigurationApp', () => {
      expect(findApp().props()).toMatchObject({
        augmentedSecurityFeatures: [],
        gitlabCiPresent: true,
        autoDevopsEnabled: false,
        canEnableAutoDevops: true,
        gitlabCiHistoryPath: '/ci/history',
        latestPipelinePath: '/pipelines/latest',
        securityTrainingEnabled: false,
        mergeRequestsEnabled: true,
      });
    });

    it('provides projectFullPath to child components', () => {
      expect(findApp().vm.projectFullPath).toBe(projectFullPath);
    });
  });

  describe('when query fails', () => {
    beforeEach(async () => {
      createComponent({
        securityConfigHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      await waitForPromises();
    });

    it('shows error alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().text()).toBe('Failed to load security configuration');
    });

    it('does not render SecurityConfigurationApp', () => {
      expect(findApp().exists()).toBe(false);
    });
  });

  describe('when query returns no data', () => {
    beforeEach(async () => {
      createComponent({
        securityConfigHandler: jest
          .fn()
          .mockResolvedValue({ data: { securityConfiguration: null } }),
      });
      await waitForPromises();
    });

    it('does not render app when no data', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findApp().exists()).toBe(false);
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when mockMergeRequestsEnabled query fails', () => {
    beforeEach(async () => {
      createComponent({
        mergeRequestsHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      await waitForPromises();
    });

    it('calls logError with error message', () => {
      expect(logger.logError).toHaveBeenCalledWith(
        'Failed to fetch merge requests enabled status',
        expect.any(Error),
      );
    });

    it('calls captureException with error', () => {
      expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(expect.any(Error));
    });

    it('still renders SecurityConfigurationApp with default value', () => {
      expect(findApp().exists()).toBe(true);
    });
  });
});
