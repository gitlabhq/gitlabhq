import { GlDisclosureDropdown } from '@gitlab/ui';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsListActions from '~/work_items/components/work_item_list_actions.vue';

describe('WorkItemsListActions component', () => {
  let wrapper;

  const projectImportJiraPath = 'gitlab-org/gitlab-test/-/import/jira';
  const rssPath = '/rss/path';
  const calendarPath = '/calendar/path';

  function createComponent(injectedProperties = {}) {
    return mountExtended(WorkItemsListActions, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide: {
        projectImportJiraPath: null,
        rssPath: null,
        calendarPath: null,
        ...injectedProperties,
      },
    });
  }

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findImportFromJiraLink = () => wrapper.findByTestId('import-from-jira-link');
  const findRssLink = () => wrapper.findByTestId('subscribe-rss');
  const findCalendarLink = () => wrapper.findByTestId('subscribe-calendar');

  describe('import from jira', () => {
    describe('when projectImportJiraPath is provided', () => {
      beforeEach(() => {
        wrapper = createComponent({ projectImportJiraPath });
      });

      it('renders the dropdown', () => {
        expect(findDropdown().exists()).toBe(true);
      });

      it('renders the import from Jira dropdown item', () => {
        expect(findImportFromJiraLink().exists()).toBe(true);
        expect(findImportFromJiraLink().props('item').href).toBe(projectImportJiraPath);
      });
    });

    describe('when projectImportJiraPath is not provided', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('does not render the dropdown if no other paths are provided', () => {
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });

  describe('subscribe dropdown options', () => {
    beforeEach(() => {
      wrapper = createComponent({ rssPath, calendarPath });
    });

    it('renders the dropdown when rssPath or calendarPath is provided', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders the RSS link with the correct href', () => {
      expect(findRssLink().exists()).toBe(true);
      expect(findRssLink().attributes('href')).toBe(rssPath);
    });

    it('renders the Calendar link with the correct href', () => {
      expect(findCalendarLink().exists()).toBe(true);
      expect(findCalendarLink().attributes('href')).toBe(calendarPath);
    });
  });
});
