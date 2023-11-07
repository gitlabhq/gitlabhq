import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from '~/vue_merge_request_widget/components/widget/app.vue';
import MrSecurityWidgetCE from '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import MrTestReportWidget from '~/vue_merge_request_widget/extensions/test_report/index.vue';
import MrTerraformWidget from '~/vue_merge_request_widget/extensions/terraform/index.vue';
import MrCodeQualityWidget from '~/vue_merge_request_widget/extensions/code_quality/index.vue';
import MrAccessibilityWidget from '~/vue_merge_request_widget/extensions/accessibility/index.vue';

describe('MR Widget App', () => {
  let wrapper;

  const createComponent = ({ mr = {} } = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        mr: {
          pipeline: {
            path: '/path/to/pipeline',
          },
          ...mr,
        },
      },
    });
  };

  it('renders widget container', () => {
    createComponent();
    expect(wrapper.findByTestId('mr-widget-app').exists()).toBe(true);
  });

  describe('MRSecurityWidget', () => {
    it('mounts MrSecurityWidgetCE', async () => {
      createComponent();

      await waitForPromises();

      expect(wrapper.findComponent(MrSecurityWidgetCE).exists()).toBe(true);
    });
  });

  describe.each`
    widgetName                | widget                   | endpoint
    ${'testReportWidget'}     | ${MrTestReportWidget}    | ${'testResultsPath'}
    ${'terraformPlansWidget'} | ${MrTerraformWidget}     | ${'terraformReportsPath'}
    ${'codeQualityWidget'}    | ${MrCodeQualityWidget}   | ${'codequalityReportsPath'}
    ${'accessibilityWidget'}  | ${MrAccessibilityWidget} | ${'accessibilityReportPath'}
  `('$widgetName', ({ widget, endpoint }) => {
    it(`is mounted when ${endpoint} is defined`, async () => {
      createComponent({ mr: { [endpoint]: `path/to/${endpoint}` } });
      await waitForPromises();

      expect(wrapper.findComponent(widget).exists()).toBe(true);
    });

    it(`is not mounted when ${endpoint} is not defined`, async () => {
      createComponent();
      await waitForPromises();

      expect(wrapper.findComponent(widget).exists()).toBe(false);
    });
  });
});
