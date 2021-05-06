import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ConfigurationTable from '~/security_configuration/components/configuration_table.vue';
import { scanners, UPGRADE_CTA } from '~/security_configuration/components/constants';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
} from '~/vue_shared/security_reports/constants';

describe('Configuration Table Component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = extendedWrapper(
      mount(ConfigurationTable, {
        provide: {
          projectPath: 'testProjectPath',
        },
      }),
    );
  };

  const findHelpLinks = () => wrapper.findAll('[data-testid="help-link"]');

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent();
  });

  describe.each(scanners.map((scanner, i) => [scanner, i]))('given scanner %s', (scanner, i) => {
    it('should match strings', () => {
      expect(wrapper.text()).toContain(scanner.name);
      expect(wrapper.text()).toContain(scanner.description);
      if (scanner.type === REPORT_TYPE_SAST) {
        expect(wrapper.findByTestId(scanner.type).text()).toBe('Configure via Merge Request');
      } else if (scanner.type === REPORT_TYPE_SECRET_DETECTION) {
        expect(wrapper.findByTestId(scanner.type).exists()).toBe(false);
      } else {
        expect(wrapper.findByTestId(scanner.type).text()).toMatchInterpolatedText(UPGRADE_CTA);
      }
    });

    it('should show expected help link', () => {
      const helpLink = findHelpLinks().at(i);
      expect(helpLink.attributes('href')).toBe(scanner.helpPath);
    });
  });
});
