import { GlDisclosureDropdown } from '@gitlab/ui';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemListActions from '~/work_items/components/work_item_list_actions.vue';
import WorkItemCsvExportModal from '~/work_items/components/work_items_csv_export_modal.vue';
import WorkItemsCsvImportModal from '~/work_items/components/work_items_csv_import_modal.vue';

describe('WorkItemsListActions component', () => {
  let wrapper;
  let glModalDirective;

  const projectImportJiraPath = 'gitlab-org/gitlab-test/-/import/jira';
  const rssPath = '/rss/path';
  const calendarPath = '/calendar/path';
  const fullPath = 'gitlab-org/gitlab-test';

  const workItemCount = 10;
  const showImportExportButtons = true;

  function createComponent(injectedProperties = {}, props = {}) {
    glModalDirective = jest.fn();
    return mountExtended(WorkItemListActions, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      provide: {
        projectImportJiraPath: null,
        rssPath: null,
        calendarPath: null,
        canImportWorkItems: false,
        canEdit: false,
        ...injectedProperties,
      },
      propsData: {
        workItemCount,
        showImportExportButtons,
        fullPath,
        ...props,
      },
    });
  }

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findExportButton = () => wrapper.findByTestId('export-as-csv-button');
  const findExportModal = () => wrapper.findComponent(WorkItemCsvExportModal);
  const findImportButton = () => wrapper.findByTestId('import-csv-button');
  const findImportModal = () => wrapper.findComponent(WorkItemsCsvImportModal);
  const findImportFromJiraLink = () => wrapper.findByTestId('import-from-jira-link');
  const findRssLink = () => wrapper.findByTestId('subscribe-rss');
  const findCalendarLink = () => wrapper.findByTestId('subscribe-calendar');

  describe('import/export options', () => {
    describe('when projectImportJiraPath is provided and canEdit is true', () => {
      beforeEach(() => {
        wrapper = createComponent({ projectImportJiraPath, canEdit: true });
      });

      it('renders the dropdown', () => {
        expect(findDropdown().exists()).toBe(true);
      });

      it('renders the import from Jira dropdown item', () => {
        expect(findImportFromJiraLink().exists()).toBe(true);
        expect(findImportFromJiraLink().props('item').href).toBe(projectImportJiraPath);
      });
    });

    describe('when projectImportJiraPath is provided but canEdit is false', () => {
      beforeEach(() => {
        wrapper = createComponent({ projectImportJiraPath, canEdit: false });
      });

      it('does not render the import from Jira dropdown item', () => {
        expect(findImportFromJiraLink().exists()).toBe(false);
      });
    });

    describe('when the showExportButton=true', () => {
      beforeEach(() => {
        wrapper = createComponent({ showExportButton: true });
      });

      it('displays the export button and the dropdown', () => {
        expect(findExportButton().exists()).toBe(true);
        expect(findDropdown().exists()).toBe(true);
      });

      it('renders the export modal', () => {
        expect(findExportModal().props()).toMatchObject({
          modalId: 'work-item-export-modal',
          workItemCount,
        });
      });

      it('opens the export modal', () => {
        findExportButton().vm.$emit('click');

        expect(glModalDirective).toHaveBeenCalledWith('work-item-export-modal');
      });
    });

    describe('when the showExportButton=false', () => {
      beforeEach(() => {
        wrapper = createComponent({ showExportButton: false });
      });

      it('does not display the export button and modal', () => {
        expect(findExportButton().exists()).toBe(false);
        expect(findExportModal().exists()).toBe(false);
      });
    });

    describe('when canImportWorkItems=true', () => {
      beforeEach(() => {
        wrapper = createComponent({ canImportWorkItems: true });
      });

      it('displays the import button and the dropdown', () => {
        expect(findImportButton().exists()).toBe(true);
        expect(findDropdown().exists()).toBe(true);
      });

      it('renders the import modal', () => {
        expect(findImportModal().props()).toMatchObject({
          modalId: 'work-item-import-modal',
          fullPath,
        });
      });

      it('opens the import modal', () => {
        findImportButton().vm.$emit('click');

        expect(glModalDirective).toHaveBeenCalledWith('work-item-import-modal');
      });
    });

    describe('when canImportWorkItems=false', () => {
      beforeEach(() => {
        wrapper = createComponent({ canImportWorkItems: false });
      });

      it('does not display the import button and modal', () => {
        expect(findImportButton().exists()).toBe(false);
        expect(findImportModal().exists()).toBe(false);
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

  describe('when no options are provided', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render the dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
