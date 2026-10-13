import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from '~/vue_merge_request_widget/components/widget/app.vue';
import MrSecurityWidgetCE from '~/vue_merge_request_widget/widgets/security_reports/mr_widget_security_reports.vue';
import MrTestReportWidget from '~/vue_merge_request_widget/widgets/test_report/index.vue';
import MrTerraformWidget from '~/vue_merge_request_widget/widgets/terraform/index.vue';
import MrCodeQualityWidget from '~/vue_merge_request_widget/widgets/code_quality/index.vue';
import MrAccessibilityWidget from '~/vue_merge_request_widget/widgets/accessibility/index.vue';
import MergeReportsWidget from '~/vue_merge_request_widget/components/widget/merge_reports_widget.vue';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';

describe('MR Widget App', () => {
  let wrapper;

  const createComponent = ({ mr = {}, glFeatures = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        mr: {
          pipeline: {
            path: '/path/to/pipeline',
          },
          ...mr,
        },
      },
      provide: { glFeatures },
      stubs,
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

  describe('report grouping', () => {
    const ReportStub = { props: ['level'], render: () => null };

    it('renders the widgets as rows of the merge reports widget, which totals what they report', async () => {
      createComponent({
        mr: { reportsTabPath: '/path/to/reports', codequalityReportsPath: '/path/to/cq' },
        glFeatures: { mergeRequestReportsWidgetGroup: true },
        stubs: { MergeReportsWidget, MrWidget, MrCodeQualityWidget: ReportStub },
      });
      await waitForPromises();

      const group = wrapper.findComponent(MergeReportsWidget);
      const row = group.findComponent(ReportStub);

      expect(row.props('level')).toBe(2);

      row.vm.$emit('loaded', 3, 'warning');
      await nextTick();

      expect(group.findComponent(MrWidget).props('summary').title).toBe(
        '%{strong_start}Merge reports (1):%{strong_end} 3 new changes across 1 report',
      );
    });

    it('hides the section while every widget is empty', async () => {
      createComponent({
        mr: { reportsTabPath: '/path/to/reports' },
        glFeatures: { mergeRequestReportsWidgetGroup: true },
        stubs: { MergeReportsWidget, MrWidget, MrSecurityWidget: ReportStub },
      });
      await waitForPromises();

      const row = wrapper.findComponent(ReportStub);

      row.vm.$emit('empty', true);
      await nextTick();

      expect(wrapper.findByTestId('mr-widget-app').isVisible()).toBe(false);

      row.vm.$emit('empty', false);
      await nextTick();

      expect(wrapper.findByTestId('mr-widget-app').isVisible()).toBe(true);
    });

    it.each`
      scenario            | mr                                                                       | glFeatures
      ${'flag is off'}    | ${{ reportsTabPath: '/path/to/reports', codequalityReportsPath: '/cq' }} | ${{}}
      ${'no reports tab'} | ${{ codequalityReportsPath: '/cq' }}                                     | ${{ mergeRequestReportsWidgetGroup: true }}
    `('renders the widgets ungrouped when the $scenario', async ({ mr, glFeatures }) => {
      createComponent({ mr, glFeatures });
      await waitForPromises();

      expect(wrapper.findComponent(MergeReportsWidget).exists()).toBe(false);
      expect(wrapper.findComponent(MrCodeQualityWidget).exists()).toBe(true);
    });
  });
});
