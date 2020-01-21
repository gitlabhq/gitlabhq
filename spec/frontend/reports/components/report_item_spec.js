import { shallowMount } from '@vue/test-utils';
import { STATUS_SUCCESS } from '~/reports/constants';
import ReportItem from '~/reports/components/report_item.vue';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import { componentNames } from '~/reports/components/issue_body';

describe('ReportItem', () => {
  describe('showReportSectionStatusIcon', () => {
    it('does not render CI Status Icon when showReportSectionStatusIcon is false', () => {
      const wrapper = shallowMount(ReportItem, {
        propsData: {
          issue: { foo: 'bar' },
          component: componentNames.TestIssueBody,
          status: STATUS_SUCCESS,
          showReportSectionStatusIcon: false,
        },
      });

      expect(wrapper.find(IssueStatusIcon).exists()).toBe(false);
    });

    it('shows status icon when unspecified', () => {
      const wrapper = shallowMount(ReportItem, {
        propsData: {
          issue: { foo: 'bar' },
          component: componentNames.TestIssueBody,
          status: STATUS_SUCCESS,
        },
      });

      expect(wrapper.find(IssueStatusIcon).exists()).toBe(true);
    });
  });
});
