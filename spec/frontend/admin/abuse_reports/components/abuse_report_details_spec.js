import { GlButton, GlCollapse } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import AbuseReportDetails from '~/admin/abuse_reports/components/abuse_report_details.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { mockAbuseReports } from '../mock_data';

describe('AbuseReportDetails', () => {
  let wrapper;
  const report = mockAbuseReports[0];

  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findCollapsible = () => wrapper.findComponent(GlCollapse);

  const createComponent = () => {
    wrapper = shallowMount(AbuseReportDetails, {
      propsData: {
        report,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders toggle button with the correct text', () => {
      expect(findToggleButton().text()).toEqual('Show details');
    });

    it('renders collapsed GlCollapse containing the report details', () => {
      const collapsible = findCollapsible();
      expect(collapsible.attributes('visible')).toBeUndefined();

      const userJoinedText = `User joined ${getTimeago().format(report.reportedUser.createdAt)}`;
      expect(collapsible.text()).toMatch(userJoinedText);
      expect(collapsible.text()).toMatch(report.message);
    });
  });

  describe('when toggled', () => {
    it('expands GlCollapse and updates toggle text', async () => {
      createComponent();

      findToggleButton().vm.$emit('click');
      await nextTick();

      expect(findToggleButton().text()).toEqual('Hide details');
      expect(findCollapsible().attributes('visible')).toBe('true');
    });
  });
});
