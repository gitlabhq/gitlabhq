import { shallowMount } from '@vue/test-utils';
import { componentNames } from '~/ci/reports/components/issue_body';
import IssueStatusIcon from '~/ci/reports/components/issue_status_icon.vue';
import ReportItem from '~/ci/reports/components/report_item.vue';
import { STATUS_SUCCESS } from '~/ci/reports/constants';

describe('ReportItem', () => {
  describe('showReportSectionStatusIcon', () => {
    it('does not render CI Status Icon when showReportSectionStatusIcon is false', () => {
      const wrapper = shallowMount(ReportItem, {
        propsData: {
          issue: { foo: 'bar' },
          component: componentNames.CodequalityIssueBody,
          status: STATUS_SUCCESS,
          showReportSectionStatusIcon: false,
        },
      });

      expect(wrapper.findComponent(IssueStatusIcon).exists()).toBe(false);
    });

    it('shows status icon when unspecified', () => {
      const wrapper = shallowMount(ReportItem, {
        propsData: {
          issue: { foo: 'bar' },
          component: componentNames.CodequalityIssueBody,
          status: STATUS_SUCCESS,
        },
      });

      expect(wrapper.findComponent(IssueStatusIcon).exists()).toBe(true);
    });
  });
});
