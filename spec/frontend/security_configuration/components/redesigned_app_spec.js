import { GlTab, GlTabs } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  SAST_NAME,
  SAST_SHORT_NAME,
  SAST_DESCRIPTION,
  SAST_HELP_PATH,
  SAST_CONFIG_HELP_PATH,
} from '~/security_configuration/components/constants';
import FeatureCard from '~/security_configuration/components/feature_card.vue';
import RedesignedSecurityConfigurationApp, {
  i18n,
} from '~/security_configuration/components/redesigned_app.vue';
import { REPORT_TYPE_SAST } from '~/vue_shared/security_reports/constants';

describe('NewApp component', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = extendedWrapper(
      mount(RedesignedSecurityConfigurationApp, {
        propsData,
      }),
    );
  };

  const findMainHeading = () => wrapper.find('h1');
  const findSubHeading = () => wrapper.find('h2');
  const findTab = () => wrapper.findComponent(GlTab);
  const findTabs = () => wrapper.findAllComponents(GlTabs);
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('basic structure', () => {
    beforeEach(() => {
      createComponent({
        augmentedSecurityFeatures: securityFeaturesMock,
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
      expect(findTabs().length).toEqual(1);
    });

    it('renders security-testing tab', () => {
      expect(findByTestId('security-testing-tab')).toExist();
    });

    it('renders sub-heading with correct text', () => {
      const subHeading = findSubHeading();
      expect(subHeading).toExist();
      expect(subHeading.text()).toContain(i18n.securityTesting);
    });

    it('renders right amount of feature cards for given props with correct props', () => {
      const cards = findFeatureCards();
      expect(cards.length).toEqual(1);
      expect(cards.at(0).props()).toEqual({ feature: securityFeaturesMock[0] });
    });

    it('should not show latest pipeline link when latestPipelinePath is not defined', () => {
      expect(findByTestId('latest-pipeline-info').exists()).toBe(false);
    });
  });

  describe('when given latestPipelinePath props', () => {
    beforeEach(() => {
      createComponent({
        augmentedSecurityFeatures: securityFeaturesMock,
        latestPipelinePath: 'test/path',
      });
    });

    it('should show latest pipeline info with correct link when latestPipelinePath is defined', () => {
      expect(findByTestId('latest-pipeline-info').exists()).toBe(true);
      expect(findByTestId('latest-pipeline-info').text()).toMatchInterpolatedText(
        i18n.securityTestingDescription,
      );
      expect(findByTestId('latest-pipeline-info').find('a').attributes('href')).toBe('test/path');
    });
  });
});
