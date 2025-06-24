import { GlCard, GlIcon, GlLink, GlButton, GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineSecretDetectionFeatureCard from '~/security_configuration/components/pipeline_secret_detection_feature_card.vue';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';
import SetValidityChecks from '~/security_configuration/graphql/set_validity_checks.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

const setMockResponse = {
  data: {
    setValidityChecks: {
      validityChecksEnabled: true,
      errors: [],
    },
  },
};

describe('PipelineSecretDetectionFeatureCard component', () => {
  let feature;
  let wrapper;
  let apolloProvider;
  let requestHandlers;
  let mockToastShow;

  const createMockApolloProvider = () => {
    requestHandlers = {
      setMutationHandler: jest.fn().mockResolvedValue(setMockResponse),
    };
    return createMockApollo([[SetValidityChecks, requestHandlers.setMutationHandler]]);
  };

  const createComponent = (propsData = {}, provide = {}, stubs = {}) => {
    apolloProvider = createMockApolloProvider();
    mockToastShow = jest.fn();
    wrapper = shallowMountExtended(PipelineSecretDetectionFeatureCard, {
      propsData: {
        feature,
        ...propsData,
      },
      provide: {
        projectFullPath: 'group/project',
        userIsProjectAdmin: true,
        glFeatures: { validityChecks: true },
        validityChecksEnabled: false,
        validityChecksAvailable: true,
        ...provide,
      },
      apolloProvider,
      stubs: {
        ManageViaMr: true,
        GlCard,
        ...stubs,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const makeFeature = (overrides = {}) => ({
    type: 'secret_detection',
    name: 'Pipeline Secret Detection',
    description: 'Analyze your source code and Git history for secrets by using CI/CD pipelines.',
    helpPath: '/help/user/application_security/secret_detection/pipeline/_index.md',
    configurationHelpPath:
      '/help/user/application_security/secret_detection/pipeline/_index.md#configuration',
    available: true,
    configured: false,
    ...overrides,
  });

  const findFeatureName = () => wrapper.find('h3');
  const findDescription = () => wrapper.find('p');
  const findLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findFeatureStatus = () => wrapper.findByTestId('feature-status');
  const findManageViaMr = () => wrapper.findComponent(ManageViaMr);
  const findSuccessIcon = () => wrapper.findComponent(GlIcon);
  const findConfigGuideButton = () => wrapper.findComponent(GlButton);
  const findValidityChecksSection = () => wrapper.findByTestId('validity-checks-section');
  const findValidityChecksToggle = () => wrapper.findByTestId('validity-checks-toggle');
  const findValidityChecksAlert = () => wrapper.findComponent(GlAlert);

  afterEach(() => {
    feature = undefined;
    apolloProvider = null;
  });

  describe('basic structure', () => {
    beforeEach(() => {
      feature = makeFeature();
      createComponent();
    });

    it('shows the name', () => {
      expect(findFeatureName().text()).toContain(feature.name);
    });

    it('shows the description', () => {
      expect(findDescription().text()).toContain(feature.description);
    });

    it('shows the help link', () => {
      const learnMoreLink = findLearnMoreLink();
      expect(learnMoreLink.attributes('href')).toBe(feature.helpPath);
      expect(learnMoreLink.attributes('target')).toBe('_blank');
      expect(learnMoreLink.text()).toBe('Learn more.');
    });

    it('should catch and emit manage-via-mr error', () => {
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(true);
      createComponent({}, {}, { ManageViaMr: false });

      const manageViaMr = findManageViaMr();
      const errorMessage = 'Test error message';

      expect(manageViaMr.exists()).toBe(true);
      manageViaMr.vm.$emit('error', errorMessage);
      expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
    });
  });

  describe('manage-via-mr', () => {
    it('is shown when feature is available and ManageViaMr can render', () => {
      feature = makeFeature({ available: true });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(true);
      createComponent();
      expect(findManageViaMr().exists()).toBe(true);
    });

    it('has the correct props', () => {
      feature = makeFeature({ available: true });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(true);
      createComponent();

      expect(findManageViaMr().props()).toMatchObject({
        feature,
        variant: 'confirm',
        category: 'primary',
      });
    });

    it('is not shown when feature is unavailable', () => {
      feature = makeFeature({ available: false });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(true);
      createComponent();
      expect(findManageViaMr().exists()).toBe(false);
    });

    it('is not shown when ManageViaMr cannot render', () => {
      feature = makeFeature({ available: true });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(false);
      createComponent();

      expect(findManageViaMr().exists()).toBe(false);
    });
  });

  describe('configuration guide button', () => {
    it('is shown when feature is available, ManageViaMr cannot render, and configurationHelpPath exists', () => {
      feature = makeFeature({
        available: true,
        configurationHelpPath: '/help',
      });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(false);
      createComponent();
      expect(findConfigGuideButton().exists()).toBe(true);
    });

    it('has the correct props', () => {
      feature = makeFeature({
        available: true,
        configurationHelpPath: '/help',
      });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(false);
      createComponent();
      const configGuideLink = findConfigGuideButton();
      expect(configGuideLink.props('icon')).toBe('external-link');
      expect(configGuideLink.attributes('href')).toBe('/help');
    });

    it('is not shown when feature is unavailable', () => {
      feature = makeFeature({
        available: false,
        configurationHelpPath: '/help',
      });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(false);
      createComponent();
      expect(findConfigGuideButton().exists()).toBe(false);
    });

    it('is not shown when configurationHelpPath is missing', () => {
      feature = makeFeature({
        available: true,
        configurationHelpPath: null,
      });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(false);
      createComponent();
      expect(findConfigGuideButton().exists()).toBe(false);
    });

    it('is not shown when ManageViaMr can render', () => {
      feature = makeFeature({
        available: true,
        configurationHelpPath: '/help',
      });
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(true);
      createComponent();
      expect(findConfigGuideButton().exists()).toBe(false);
    });
  });

  describe('status', () => {
    describe.each`
      context                      | available | configured | expectedStatus
      ${'a configured feature'}    | ${true}   | ${true}    | ${'Enabled'}
      ${'an unconfigured feature'} | ${true}   | ${false}   | ${'Not enabled'}
      ${'an unavailable feature'}  | ${false}  | ${false}   | ${''}
    `('given $context', ({ available, configured, expectedStatus }) => {
      beforeEach(() => {
        feature = makeFeature({ available, configured });
        createComponent();
      });

      it(`shows the status "${expectedStatus}"`, () => {
        expect(findFeatureStatus().text().trim()).toBe(expectedStatus);
      });

      if (configured) {
        it('shows a success icon', () => {
          expect(findSuccessIcon().props('name')).toBe('check-circle-filled');
        });
      }
    });
  });

  describe('validity checks section', () => {
    beforeEach(() => {
      feature = makeFeature({ available: true });
    });

    it('is shown when feature flag is enabled', () => {
      createComponent({}, { glFeatures: { validityChecks: true } });
      expect(findValidityChecksSection().exists()).toBe(true);
    });

    it('is not shown when feature flag is disabled', () => {
      createComponent({}, { glFeatures: { validityChecks: false } });
      expect(findValidityChecksSection().exists()).toBe(false);
    });

    it('is not shown when feature is unavailable', () => {
      feature = makeFeature({ available: false });
      createComponent({}, { glFeatures: { validityChecks: true } });
      expect(findValidityChecksSection().exists()).toBe(false);
    });

    describe('validity checks toggle', () => {
      it('has the correct default value when validityChecksEnabled is true', () => {
        createComponent({}, { validityChecksEnabled: true });
        const toggle = findValidityChecksToggle();
        expect(toggle.props('value')).toBe(true);
      });

      it('has the correct default value when validityChecksEnabled is false', () => {
        createComponent({}, { validityChecksEnabled: false });
        const toggle = findValidityChecksToggle();
        expect(toggle.props('value')).toBe(false);
      });

      it('is unlocked when validityChecksAvailable is true and pipeline secret detection is configured', () => {
        feature = makeFeature({ available: true, configured: true });
        createComponent({}, { validityChecksAvailable: true });
        const toggle = findValidityChecksToggle();
        expect(toggle.props('disabled')).toBe(false);
      });

      it('is locked when validityChecksAvailable is false', () => {
        feature = makeFeature({ available: true, configured: true });
        createComponent({}, { validityChecksAvailable: false });
        const toggle = findValidityChecksToggle();
        expect(toggle.props('disabled')).toBe(true);
      });

      it('is locked when pipeline secret detection is not configured', () => {
        feature = makeFeature({ available: true, configured: false });
        createComponent({}, { validityChecksAvailable: true });
        const toggle = findValidityChecksToggle();
        expect(toggle.props('disabled')).toBe(true);
      });

      it('calls mutation on toggle change with correct payload', async () => {
        feature = makeFeature({ available: true, configured: true });
        createComponent();
        const toggle = findValidityChecksToggle();
        expect(toggle.props('value')).toBe(false);
        toggle.vm.$emit('change', true);

        expect(requestHandlers.setMutationHandler).toHaveBeenCalledWith({
          input: {
            namespacePath: 'group/project',
            enable: true,
          },
        });

        await waitForPromises();

        expect(toggle.props('value')).toBe(true);
        expect(wrapper.text()).toContain('Enabled');
      });

      it('shows success toast when toggle succeeds', async () => {
        feature = makeFeature({ available: true, configured: true });
        createComponent();

        const toggle = findValidityChecksToggle();
        expect(toggle.props('value')).toBe(false);

        toggle.vm.$emit('change', true);

        expect(requestHandlers.setMutationHandler).toHaveBeenCalledWith({
          input: {
            namespacePath: 'group/project',
            enable: true,
          },
        });

        await waitForPromises();

        expect(toggle.props('value')).toBe(true);
        expect(mockToastShow).toHaveBeenCalledWith('Validity checks enabled');
      });

      it('shows error alert when an error message is set', async () => {
        feature = makeFeature({ available: true, configured: true });
        createComponent();

        requestHandlers.setMutationHandler.mockReset();
        requestHandlers.setMutationHandler.mockResolvedValue({
          data: {
            setValidityChecks: {
              validityChecksEnabled: null,
              errors: ['data response with errors'],
            },
          },
        });

        const toggle = findValidityChecksToggle();
        toggle.vm.$emit('change', true);

        await waitForPromises();

        expect(findValidityChecksAlert().exists()).toBe(true);
      });

      it('handles GraphQL mutation errors', async () => {
        feature = makeFeature({ available: true, configured: true });
        createComponent();

        requestHandlers.setMutationHandler.mockReset();
        requestHandlers.setMutationHandler.mockRejectedValue(new Error('Network error'));

        const toggle = findValidityChecksToggle();
        toggle.vm.$emit('change', true);

        expect(requestHandlers.setMutationHandler).toHaveBeenCalledWith({
          input: {
            namespacePath: 'group/project',
            enable: true,
          },
        });

        await waitForPromises();

        expect(findValidityChecksAlert().exists()).toBe(true);
      });
    });
  });

  describe('error handling', () => {
    beforeEach(() => {
      feature = makeFeature();
      jest.spyOn(ManageViaMr, 'canRender').mockReturnValue(true);
      createComponent({}, {}, { ManageViaMr: false });
    });

    it('emits error when ManageViaMr emits error', () => {
      const errorMessage = 'Something went wrong';
      const manageViaMr = findManageViaMr();

      expect(manageViaMr.exists()).toBe(true);
      manageViaMr.vm.$emit('error', errorMessage);
      expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
    });
  });
});
