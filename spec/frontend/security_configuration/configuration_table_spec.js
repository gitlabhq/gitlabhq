import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ConfigurationTable from '~/security_configuration/components/configuration_table.vue';
import { features, UPGRADE_CTA } from '~/security_configuration/components/features_constants';

import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DAST_PROFILES,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_LICENSE_COMPLIANCE,
} from '~/vue_shared/security_reports/constants';

describe('Configuration Table Component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = extendedWrapper(mount(ConfigurationTable, {}));
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent();
  });

  it.each(features)('should match strings', (feature) => {
    expect(wrapper.text()).toContain(feature.name);
    expect(wrapper.text()).toContain(feature.description);

    if (feature.type === REPORT_TYPE_SAST) {
      expect(wrapper.findByTestId(feature.type).text()).toBe('Configure via Merge Request');
    } else if (
      [
        REPORT_TYPE_DAST,
        REPORT_TYPE_DAST_PROFILES,
        REPORT_TYPE_DEPENDENCY_SCANNING,
        REPORT_TYPE_CONTAINER_SCANNING,
        REPORT_TYPE_COVERAGE_FUZZING,
        REPORT_TYPE_LICENSE_COMPLIANCE,
      ].includes(feature.type)
    ) {
      expect(wrapper.findByTestId(feature.type).text()).toMatchInterpolatedText(UPGRADE_CTA);
    }
  });
});
