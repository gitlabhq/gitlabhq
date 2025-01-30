import { nextTick } from 'vue';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from '~/vue_merge_request_widget/components/widget/app.vue';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import MrSecurityWidgetCE from '~/vue_merge_request_widget/widgets/security_reports/mr_widget_security_reports.vue';
import MrTestReportWidget from '~/vue_merge_request_widget/widgets/test_report/index.vue';
import MrTerraformWidget from '~/vue_merge_request_widget/widgets/terraform/index.vue';
import MrCodeQualityWidget from '~/vue_merge_request_widget/widgets/code_quality/index.vue';
import MrAccessibilityWidget from '~/vue_merge_request_widget/widgets/accessibility/index.vue';

describe('MR Widget App', () => {
  let wrapper;

  const createComponent = ({ mr = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(App, {
      provide,
      propsData: {
        mr: {
          pipeline: {
            path: '/path/to/pipeline',
          },
          ...mr,
        },
      },
      stubs: { GlSprintf },
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

  describe('when mrReportsTab is enabled', () => {
    it('hides widgets by default', () => {
      createComponent({ provide: { glFeatures: { mrReportsTab: true } } });

      expect(wrapper.findByTestId('reports-widgets-container').isVisible()).toBe(false);
    });

    it('expands widgets when toggling state container', async () => {
      createComponent({ provide: { glFeatures: { mrReportsTab: true } } });

      wrapper.findComponent(StateContainer).vm.$emit('toggle');

      await waitForPromises();

      expect(wrapper.findByTestId('reports-widgets-container').isVisible()).toBe(true);
    });

    it('shows findings count after widget emits loaded event', async () => {
      createComponent({
        mr: { testResultsPath: 'path/to/testResultsPath' },
        provide: { glFeatures: { mrReportsTab: true } },
      });

      await waitForPromises();

      wrapper.findComponent(MrTestReportWidget).vm.$emit('loaded', 10);

      await nextTick();

      expect(wrapper.findComponent(StateContainer).text()).toContain('10 findings');
    });
  });
});
