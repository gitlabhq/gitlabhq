import { GlCard, GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineSecretDetectionFeatureCard from '~/security_configuration/components/pipeline_secret_detection_feature_card.vue';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';

describe('PipelineSecretDetectionFeatureCard component', () => {
  let feature;
  let wrapper;

  const createComponent = (propsData = {}, provide = {}, stubs = {}) => {
    wrapper = shallowMountExtended(PipelineSecretDetectionFeatureCard, {
      propsData: {
        feature,
        ...propsData,
      },
      provide: {
        projectFullPath: 'group/project',
        userIsProjectAdmin: true,
        ...provide,
      },
      stubs: {
        ManageViaMr: true,
        GlCard,
        ...stubs,
      },
    });
  };

  const makeFeature = (overrides = {}) => ({
    type: 'secret_detection',
    name: 'Secret Detection',
    description: 'Analyze your source code for known secrets.',
    helpPath: '/help/user/application_security/secret_detection',
    configurationHelpPath: '/help/user/application_security/secret_detection/configuration',
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

  afterEach(() => {
    feature = undefined;
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
