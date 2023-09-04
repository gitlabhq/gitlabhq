import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { sprintf } from '~/locale';
import AcitivityHistoryItem from '~/admin/abuse_report/components/activity_history_item.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockAbuseReport } from '../mock_data';

describe('AcitivityHistoryItem', () => {
  let wrapper;

  const { report } = mockAbuseReport;

  const findHistoryItem = () => wrapper.findComponent(HistoryItem);
  const findTimeAgo = () => wrapper.findComponent(TimeAgoTooltip);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(AcitivityHistoryItem, {
      propsData: {
        report,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the icon', () => {
    expect(findHistoryItem().props('icon')).toBe('warning');
  });

  describe('rendering the title', () => {
    it('renders the reporters name and the category', () => {
      const title = sprintf('Reported by %{name} for %{category}.', {
        name: report.reporter.name,
        category: report.category,
      });
      expect(findHistoryItem().text()).toContain(title);
    });

    describe('when the reporter is not defined', () => {
      beforeEach(() => {
        createComponent({ report: { ...report, reporter: undefined } });
      });

      it('renders the `No user found` as the reporters name and the category', () => {
        const title = sprintf('Reported by %{name} for %{category}.', {
          name: 'No user found',
          category: report.category,
        });
        expect(findHistoryItem().text()).toContain(title);
      });
    });
  });

  it('renders the time-ago tooltip', () => {
    expect(findTimeAgo().props('time')).toBe(report.reportedAt);
  });
});
