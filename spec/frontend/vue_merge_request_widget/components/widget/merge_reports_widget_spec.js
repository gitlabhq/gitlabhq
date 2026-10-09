import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeReportsWidget from '~/vue_merge_request_widget/components/widget/merge_reports_widget.vue';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';

describe('MergeReportsWidget', () => {
  let wrapper;
  let slotProps;

  const createComponent = () => {
    slotProps = undefined;
    wrapper = shallowMountExtended(MergeReportsWidget, {
      propsData: {
        mr: { reportsTabPath: '/group/project/-/merge_requests/1/reports' },
      },
      stubs: { MrWidget },
      scopedSlots: {
        reports(props) {
          slotProps = props;
          return null;
        },
      },
    });
  };

  const findWidget = () => wrapper.findComponent(MrWidget);
  const summaryTitle = () => findWidget().props('summary').title;

  const loadReport = (key, count, status) => {
    slotProps.onReportLoaded(key, count, status);

    return nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  it('links to the reports tab', () => {
    expect(findWidget().props('actionButtons')).toMatchObject([
      { href: '/group/project/-/merge_requests/1/reports' },
    ]);
  });

  describe('summary', () => {
    it('counts only the reports that have reported a row', async () => {
      await loadReport('MrCodeQualityWidget', 0, 'success');
      await loadReport('MrTestReportWidget', 0, 'success');

      expect(summaryTitle()).toBe('%{strong_start}Merge reports (2)%{strong_end}');
    });

    it('totals the changes across the reports that found one', async () => {
      await loadReport('MrCodeQualityWidget', 13, 'warning');
      await loadReport('MrSecurityWidgetEE', 22, 'failed');
      await loadReport('MrTestReportWidget', 0, 'success');

      expect(summaryTitle()).toBe(
        '%{strong_start}Merge reports (3):%{strong_end} 35 new changes across 2 reports',
      );
    });

    it('uses singular wording for a single change in a single report', async () => {
      await loadReport('MrCodeQualityWidget', 1, 'warning');

      expect(summaryTitle()).toBe(
        '%{strong_start}Merge reports (1):%{strong_end} 1 new change across 1 report',
      );
    });

    it('replaces the count when a report reports again', async () => {
      await loadReport('MrLoadPerformanceWidget', 2, 'warning');
      await loadReport('MrLoadPerformanceWidget', 5, 'warning');

      expect(summaryTitle()).toBe(
        '%{strong_start}Merge reports (1):%{strong_end} 5 new changes across 1 report',
      );
    });
  });

  describe('status icon', () => {
    it.each`
      statuses                            | expected
      ${['success', 'neutral']}           | ${'success'}
      ${['warning', 'success']}           | ${'warning'}
      ${['warning', 'failed', 'success']} | ${'failed'}
      ${['warning', 'error']}             | ${'error'}
    `('is $expected for $statuses', async ({ statuses, expected }) => {
      await Promise.all(statuses.map((status, index) => loadReport(`report-${index}`, 0, status)));

      expect(findWidget().props('statusIconName')).toBe(expected);
    });

    it('ignores a report that reports no status', async () => {
      await loadReport('MrStatusChecksWidget', 0, undefined);
      await loadReport('MrCodeQualityWidget', 1, 'warning');

      expect(findWidget().props('statusIconName')).toBe('warning');
    });
  });

  describe('which rows are visible', () => {
    it('shows only the failed reports while collapsed', async () => {
      await loadReport('MrCodeQualityWidget', 3, 'warning');

      expect(findWidget().props('showContentWhenCollapsed')).toBe(false);
      expect(slotProps.isReportVisible('MrCodeQualityWidget')).toBe(false);

      await loadReport('MrTestReportWidget', 0, 'failed');
      await loadReport('MrSecurityWidgetEE', 0, 'error');

      expect(findWidget().props('showContentWhenCollapsed')).toBe(true);
      expect(slotProps.isReportVisible('MrTestReportWidget')).toBe(true);
      expect(slotProps.isReportVisible('MrSecurityWidgetEE')).toBe(true);
      expect(slotProps.isReportVisible('MrCodeQualityWidget')).toBe(false);
    });

    it('shows every report once expanded', async () => {
      await loadReport('MrCodeQualityWidget', 3, 'warning');

      findWidget().vm.$emit('toggle', { expanded: true });
      await nextTick();

      expect(slotProps.isReportVisible('MrCodeQualityWidget')).toBe(true);
    });
  });
});
