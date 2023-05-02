import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { sprintf } from '~/locale';
import HistoryItems from '~/admin/abuse_report/components/history_items.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { HISTORY_ITEMS_I18N } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('HistoryItems', () => {
  let wrapper;

  const { report, reporter } = mockAbuseReport;

  const findHistoryItem = () => wrapper.findComponent(HistoryItem);
  const findTimeAgo = () => wrapper.findComponent(TimeAgoTooltip);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(HistoryItems, {
      propsData: {
        report,
        reporter,
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
      const title = sprintf(HISTORY_ITEMS_I18N.reportedByForCategory, {
        name: reporter.name,
        category: report.category,
      });
      expect(findHistoryItem().text()).toContain(title);
    });

    describe('when the reporter is not defined', () => {
      beforeEach(() => {
        createComponent({ reporter: undefined });
      });

      it('renders the `No user found` as the reporters name and the category', () => {
        const title = sprintf(HISTORY_ITEMS_I18N.reportedByForCategory, {
          name: HISTORY_ITEMS_I18N.deletedReporter,
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
