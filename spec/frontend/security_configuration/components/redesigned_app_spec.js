import { GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  SAST_NAME,
  SAST_SHORT_NAME,
  SAST_DESCRIPTION,
  SAST_HELP_PATH,
  SAST_CONFIG_HELP_PATH,
  LICENSE_COMPLIANCE_NAME,
  LICENSE_COMPLIANCE_DESCRIPTION,
  LICENSE_COMPLIANCE_HELP_PATH,
} from '~/security_configuration/components/constants';
import FeatureCard from '~/security_configuration/components/feature_card.vue';
import RedesignedSecurityConfigurationApp, {
  i18n,
} from '~/security_configuration/components/redesigned_app.vue';
import {
  REPORT_TYPE_LICENSE_COMPLIANCE,
  REPORT_TYPE_SAST,
} from '~/vue_shared/security_reports/constants';

describe('redesigned App component', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = extendedWrapper(
      mount(RedesignedSecurityConfigurationApp, {
        propsData,
      }),
    );
  };

  const findMainHeading = () => wrapper.find('h1');
  const findTab = () => wrapper.findComponent(GlTab);
  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findByTestId = (id) => wrapper.findByTestId(id);
  const findFeatureCards = () => wrapper.findAllComponents(FeatureCard);

  const securityFeaturesMock = [
    {
      name: SAST_NAME,
      shortName: SAST_SHORT_NAME,
      description: SAST_DESCRIPTION,
      helpPath: SAST_HELP_PATH,
      configurationHelpPath: SAST_CONFIG_HELP_PATH,
      type: REPORT_TYPE_SAST,
      available: true,
    },
  ];

  const complianceFeaturesMock = [
    {
      name: LICENSE_COMPLIANCE_NAME,
      description: LICENSE_COMPLIANCE_DESCRIPTION,
      helpPath: LICENSE_COMPLIANCE_HELP_PATH,
      type: REPORT_TYPE_LICENSE_COMPLIANCE,
      configurationHelpPath: LICENSE_COMPLIANCE_HELP_PATH,
    },
  ];

  afterEach(() => {
    wrapper.destroy();
  });

  describe('basic structure', () => {
    beforeEach(() => {
      createComponent({
        augmentedSecurityFeatures: securityFeaturesMock,
        augmentedComplianceFeatures: complianceFeaturesMock,
      });
    });

    it('renders main-heading with correct text', () => {
      const mainHeading = findMainHeading();
      expect(mainHeading).toExist();
      expect(mainHeading.text()).toContain('Security Configuration');
    });

    it('renders GlTab Component ', () => {
      expect(findTab()).toExist();
    });

    it('renders right amount of tabs with correct title ', () => {
      expect(findTabs()).toHaveLength(2);
    });

    it('renders security-testing tab', () => {
      expect(findByTestId('security-testing-tab').exists()).toBe(true);
    });

    it('renders compliance-testing tab', () => {
      expect(findByTestId('compliance-testing-tab').exists()).toBe(true);
    });

    it('renders right amount of feature cards for given props with correct props', () => {
      const cards = findFeatureCards();
      expect(cards).toHaveLength(2);
      expect(cards.at(0).props()).toEqual({ feature: securityFeaturesMock[0] });
      expect(cards.at(1).props()).toEqual({ feature: complianceFeaturesMock[0] });
    });

    it('should not show latest pipeline link when latestPipelinePath is not defined', () => {
      expect(findByTestId('latest-pipeline-info').exists()).toBe(false);
    });
  });

  describe('when given latestPipelinePath props', () => {
    beforeEach(() => {
      createComponent({
        augmentedSecurityFeatures: securityFeaturesMock,
        augmentedComplianceFeatures: complianceFeaturesMock,
        latestPipelinePath: 'test/path',
      });
    });

    it('should show latest pipeline info on the security tab  with correct link when latestPipelinePath is defined', () => {
      const latestPipelineInfoSecurity = findByTestId('latest-pipeline-info-security');

      expect(latestPipelineInfoSecurity.exists()).toBe(true);
      expect(latestPipelineInfoSecurity.text()).toMatchInterpolatedText(
        i18n.securityTestingDescription,
      );
      expect(latestPipelineInfoSecurity.find('a').attributes('href')).toBe('test/path');
    });

    it('should show latest pipeline info on the compliance tab  with correct link when latestPipelinePath is defined', () => {
      const latestPipelineInfoCompliance = findByTestId('latest-pipeline-info-compliance');

      expect(latestPipelineInfoCompliance.exists()).toBe(true);
      expect(latestPipelineInfoCompliance.text()).toMatchInterpolatedText(
        i18n.securityTestingDescription,
      );
      expect(latestPipelineInfoCompliance.find('a').attributes('href')).toBe('test/path');
    });
  });
});
