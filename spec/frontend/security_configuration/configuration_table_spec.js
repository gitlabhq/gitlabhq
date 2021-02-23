import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ConfigurationTable from '~/security_configuration/components/configuration_table.vue';
import { features, UPGRADE_CTA } from '~/security_configuration/components/features_constants';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
} from '~/vue_shared/security_reports/constants';

describe('Configuration Table Component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = extendedWrapper(mount(ConfigurationTable, {}));
  };

  const findHelpLinks = () => wrapper.findAll('[data-testid="help-link"]');

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent();
  });

  describe.each(features.map((feature, i) => [feature, i]))('given feature %s', (feature, i) => {
    it('should match strings', () => {
      expect(wrapper.text()).toContain(feature.name);
      expect(wrapper.text()).toContain(feature.description);
      if (feature.type === REPORT_TYPE_SAST) {
        expect(wrapper.findByTestId(feature.type).text()).toBe('Configure via Merge Request');
      } else if (feature.type !== REPORT_TYPE_SECRET_DETECTION) {
        expect(wrapper.findByTestId(feature.type).text()).toMatchInterpolatedText(UPGRADE_CTA);
      }
    });

    it('should show expected help link', () => {
      const helpLink = findHelpLinks().at(i);
      expect(helpLink.attributes('href')).toBe(feature.helpPath);
    });
  });
});
