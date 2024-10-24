import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlTable } from '@gitlab/ui';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import TimelogsTable from '~/time_tracking/components/timelogs_table.vue';
import TimelogSourceCell from '~/time_tracking/components/timelog_source_cell.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { STATUS_OPEN, STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';

const baseTimelogMock = {
  timeSpent: 600,
  project: {
    fullPath: 'group/project',
  },
  user: {
    name: 'John Smith',
    avatarUrl: 'https://example.gitlab.com/john.jpg',
    webPath: 'https://example.gitlab.com/john',
  },
  spentAt: '2023-03-27T21:00:00Z',
  note: null,
  summary: 'Summary from timelog field',
  issue: {
    title: 'Issue title',
    webUrl: 'https://example.gitlab.com/issue_url_a',
    state: STATUS_OPEN,
    reference: '#111',
  },
  mergeRequest: null,
};

const timelogsMock = [
  baseTimelogMock,
  {
    timeSpent: 3600,
    project: {
      fullPath: 'group/project_b',
    },
    user: {
      name: 'Paul Reed',
      avatarUrl: 'https://example.gitlab.com/paul.jpg',
      webPath: 'https://example.gitlab.com/paul',
    },
    spentAt: '2023-03-28T16:00:00Z',
    note: {
      body: 'Summary from the body',
    },
    summary: null,
    issue: {
      title: 'Other issue title',
      webUrl: 'https://example.gitlab.com/issue_url_b',
      state: STATUS_CLOSED,
      reference: '#112',
    },
    mergeRequest: null,
  },
  {
    timeSpent: 27 * 60 * 60, // 27h or 3d 3h (3 days of 8 hours)
    project: {
      fullPath: 'group/project_b',
    },
    user: {
      name: 'Les Gibbons',
      avatarUrl: 'https://example.gitlab.com/les.jpg',
      webPath: 'https://example.gitlab.com/les',
    },
    spentAt: '2023-03-28T18:00:00Z',
    note: null,
    summary: 'Other timelog summary',
    issue: null,
    mergeRequest: {
      title: 'MR title',
      webUrl: 'https://example.gitlab.com/mr_url',
      state: STATUS_MERGED,
      reference: '!99',
    },
  },
];

describe('TimelogsTable component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findTable().find('tbody').findAll('tr');
  const findRowSpentAt = (rowIndex) =>
    extendedWrapper(findTableRows().at(rowIndex)).findByTestId('date-container');
  const findRowSource = (rowIndex) => findTableRows().at(rowIndex).findComponent(TimelogSourceCell);
  const findRowUser = (rowIndex) => findTableRows().at(rowIndex).findComponent(UserAvatarLink);
  const findRowTimeSpent = (rowIndex) =>
    extendedWrapper(findTableRows().at(rowIndex)).findByTestId('time-spent-container');
  const findRowSummary = (rowIndex) =>
    extendedWrapper(findTableRows().at(rowIndex)).findByTestId('summary-container');

  const mountComponent = (props = {}) => {
    wrapper = mountExtended(TimelogsTable, {
      propsData: {
        entries: timelogsMock,
        limitToHours: false,
        ...props,
      },
      stubs: { GlTable },
    });
  };

  describe('when there are no entries', () => {
    it('show the empty table message and no rows', () => {
      mountComponent({ entries: [] });

      expect(findTable().text()).toContain('There are no records to show');
      expect(findTableRows()).toHaveLength(1);
    });
  });

  describe('when there are some entries', () => {
    it('does not show the empty table message and has the correct number of rows', () => {
      mountComponent();

      expect(findTable().text()).not.toContain('There are no records to show');
      expect(findTableRows()).toHaveLength(3);
    });

    describe('Spent at column', () => {
      it('shows the spent at value with in the correct format', () => {
        mountComponent();

        expect(findRowSpentAt(0).text()).toBe(
          localeDateFormat.asDateTimeFull.format(baseTimelogMock.spentAt),
        );
      });
    });

    describe('Source column', () => {
      it('creates the source cell component passing the right props', () => {
        mountComponent();

        expect(findRowSource(0).props()).toMatchObject({
          timelog: timelogsMock[0],
        });
        expect(findRowSource(1).props()).toMatchObject({
          timelog: timelogsMock[1],
        });
        expect(findRowSource(2).props()).toMatchObject({
          timelog: timelogsMock[2],
        });
      });
    });

    describe('User column', () => {
      it('creates the user avatar component passing the right props', () => {
        mountComponent();

        expect(findRowUser(0).props()).toMatchObject({
          linkHref: timelogsMock[0].user.webPath,
          imgSrc: timelogsMock[0].user.avatarUrl,
          imgSize: 16,
          imgAlt: timelogsMock[0].user.name,
          tooltipText: timelogsMock[0].user.name,
          username: timelogsMock[0].user.name,
        });
        expect(findRowUser(1).props()).toMatchObject({
          linkHref: timelogsMock[1].user.webPath,
          imgSrc: timelogsMock[1].user.avatarUrl,
          imgSize: 16,
          imgAlt: timelogsMock[1].user.name,
          tooltipText: timelogsMock[1].user.name,
          username: timelogsMock[1].user.name,
        });
        expect(findRowUser(2).props()).toMatchObject({
          linkHref: timelogsMock[2].user.webPath,
          imgSrc: timelogsMock[2].user.avatarUrl,
          imgSize: 16,
          imgAlt: timelogsMock[2].user.name,
          tooltipText: timelogsMock[2].user.name,
          username: timelogsMock[2].user.name,
        });
      });
    });

    describe('Time spent column', () => {
      it('shows the time spent value with the correct format when `limitToHours` is false', () => {
        mountComponent();

        expect(findRowTimeSpent(0).text()).toBe('10m');
        expect(findRowTimeSpent(1).text()).toBe('1h');
        expect(findRowTimeSpent(2).text()).toBe('3d 3h');
      });

      it('shows the time spent value with the correct format when `limitToHours` is true', () => {
        mountComponent({ limitToHours: true });

        expect(findRowTimeSpent(0).text()).toBe('10m');
        expect(findRowTimeSpent(1).text()).toBe('1h');
        expect(findRowTimeSpent(2).text()).toBe('27h');
      });
    });

    describe('Summary column', () => {
      it('shows the summary from the note when note body is present and not empty', () => {
        mountComponent({
          entries: [{ ...baseTimelogMock, note: { body: 'Summary from note body' } }],
        });

        expect(findRowSummary(0).text()).toBe('Summary from note body');
      });

      it('shows the summary from the timelog note body is present but empty', () => {
        mountComponent({
          entries: [{ ...baseTimelogMock, note: { body: '' } }],
        });

        expect(findRowSummary(0).text()).toBe('Summary from timelog field');
      });

      it('shows the summary from the timelog note body is not present', () => {
        mountComponent({
          entries: [baseTimelogMock],
        });

        expect(findRowSummary(0).text()).toBe('Summary from timelog field');
      });
    });
  });
});
