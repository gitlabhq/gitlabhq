import { GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import AutoDevopsAlert from '~/security_configuration/components/auto_dev_ops_alert.vue';
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
import UpgradeBanner from '~/security_configuration/components/upgrade_banner.vue';
import {
  REPORT_TYPE_LICENSE_COMPLIANCE,
  REPORT_TYPE_SAST,
} from '~/vue_shared/security_reports/constants';

const upgradePath = '/upgrade';
const autoDevopsHelpPagePath = '/autoDevopsHelpPagePath';
const autoDevopsPath = '/autoDevopsPath';
const gitlabCiHistoryPath = 'test/historyPath';

describe('redesigned App component', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const createComponent = ({ shouldShowCallout = true, ...propsData }) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = extendedWrapper(
      mount(RedesignedSecurityConfigurationApp, {
        propsData,
        provide: {
          upgradePath,
          autoDevopsHelpPagePath,
          autoDevopsPath,
        },
        stubs: {
          UserCalloutDismisser: makeMockUserCalloutDismisser({
            dismiss: userCalloutDismissSpy,
            shouldShowCallout,
          }),
        },
      }),
    );
  };

  const findMainHeading = () => wrapper.find('h1');
  const findTab = () => wrapper.findComponent(GlTab);
  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findByTestId = (id) => wrapper.findByTestId(id);
  const findFeatureCards = () => wrapper.findAllComponents(FeatureCard);
  const findLink = ({ href, text, container = wrapper }) => {
    const selector = `a[href="${href}"]`;
    const link = container.find(selector);

    if (link.exists() && link.text() === text) {
      return link;
    }

    return wrapper.find(`${selector} does not exist`);
  };
  const findSecurityViewHistoryLink = () =>
    findLink({
      href: gitlabCiHistoryPath,
      text: i18n.configurationHistory,
      container: findByTestId('security-testing-tab'),
    });
  const findComplianceViewHistoryLink = () =>
    findLink({
      href: gitlabCiHistoryPath,
      text: i18n.configurationHistory,
      container: findByTestId('compliance-testing-tab'),
    });
  const findUpgradeBanner = () => wrapper.findComponent(UpgradeBanner);
  const findAutoDevopsAlert = () => wrapper.findComponent(AutoDevopsAlert);

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

    it('renders a basic description', () => {
      expect(wrapper.text()).toContain(i18n.description);
    });

    it('should not show latest pipeline link when latestPipelinePath is not defined', () => {
      expect(findByTestId('latest-pipeline-info').exists()).toBe(false);
    });

    it('should not show configuration History Link when gitlabCiPresent & gitlabCiHistoryPath are not defined', () => {
      expect(findComplianceViewHistoryLink().exists()).toBe(false);
      expect(findSecurityViewHistoryLink().exists()).toBe(false);
    });
  });

  describe('autoDevOpsAlert', () => {
    describe('given the right props', () => {
      beforeEach(() => {
        createComponent({
          augmentedSecurityFeatures: securityFeaturesMock,
          augmentedComplianceFeatures: complianceFeaturesMock,
          autoDevopsEnabled: false,
          gitlabCiPresent: false,
          canEnableAutoDevops: true,
        });
      });

      it('should show AutoDevopsAlert', () => {
        expect(findAutoDevopsAlert().exists()).toBe(true);
      });

      it('calls the dismiss callback when closing the AutoDevopsAlert', () => {
        expect(userCalloutDismissSpy).not.toHaveBeenCalled();

        findAutoDevopsAlert().vm.$emit('dismiss');

        expect(userCalloutDismissSpy).toHaveBeenCalledTimes(1);
      });
    });

    describe('given the wrong props', () => {
      beforeEach(() => {
        createComponent({
          augmentedSecurityFeatures: securityFeaturesMock,
          augmentedComplianceFeatures: complianceFeaturesMock,
        });
      });
      it('should not show AutoDevopsAlert', () => {
        expect(findAutoDevopsAlert().exists()).toBe(false);
      });
    });
  });

  describe('upgrade banner', () => {
    const makeAvailable = (available) => (feature) => ({ ...feature, available });

    describe('given at least one unavailable feature', () => {
      beforeEach(() => {
        createComponent({
          augmentedSecurityFeatures: securityFeaturesMock,
          augmentedComplianceFeatures: complianceFeaturesMock.map(makeAvailable(false)),
        });
      });

      it('renders the banner', () => {
        expect(findUpgradeBanner().exists()).toBe(true);
      });

      it('calls the dismiss callback when closing the banner', () => {
        expect(userCalloutDismissSpy).not.toHaveBeenCalled();

        findUpgradeBanner().vm.$emit('close');

        expect(userCalloutDismissSpy).toHaveBeenCalledTimes(1);
      });
    });

    describe('given at least one unavailable feature, but banner is already dismissed', () => {
      beforeEach(() => {
        createComponent({
          augmentedSecurityFeatures: securityFeaturesMock,
          augmentedComplianceFeatures: complianceFeaturesMock.map(makeAvailable(false)),
          shouldShowCallout: false,
        });
      });

      it('does not render the banner', () => {
        expect(findUpgradeBanner().exists()).toBe(false);
      });
    });

    describe('given all features are available', () => {
      beforeEach(() => {
        createComponent({
          augmentedSecurityFeatures: securityFeaturesMock.map(makeAvailable(true)),
          augmentedComplianceFeatures: complianceFeaturesMock.map(makeAvailable(true)),
        });
      });

      it('does not render the banner', () => {
        expect(findUpgradeBanner().exists()).toBe(false);
      });
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

      expect(latestPipelineInfoSecurity.text()).toMatchInterpolatedText(
        i18n.latestPipelineDescription,
      );
      expect(latestPipelineInfoSecurity.find('a').attributes('href')).toBe('test/path');
    });

    it('should show latest pipeline info on the compliance tab  with correct link when latestPipelinePath is defined', () => {
      const latestPipelineInfoCompliance = findByTestId('latest-pipeline-info-compliance');

      expect(latestPipelineInfoCompliance.text()).toMatchInterpolatedText(
        i18n.latestPipelineDescription,
      );
      expect(latestPipelineInfoCompliance.find('a').attributes('href')).toBe('test/path');
    });
  });

  describe('given gitlabCiPresent & gitlabCiHistoryPath props', () => {
    beforeEach(() => {
      createComponent({
        augmentedSecurityFeatures: securityFeaturesMock,
        augmentedComplianceFeatures: complianceFeaturesMock,
        gitlabCiPresent: true,
        gitlabCiHistoryPath,
      });
    });

    it('should show configuration History Link', () => {
      expect(findComplianceViewHistoryLink().exists()).toBe(true);
      expect(findSecurityViewHistoryLink().exists()).toBe(true);

      expect(findComplianceViewHistoryLink().attributes('href')).toBe('test/historyPath');
      expect(findSecurityViewHistoryLink().attributes('href')).toBe('test/historyPath');
    });
  });
});
