import { createMockDirective } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CsvExportModal from '~/issuable/components/csv_export_modal.vue';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import CsvImportModal from '~/issuable/components/csv_import_modal.vue';

describe('CsvImportExportButtons', () => {
  let wrapper;
  let glModalDirective;

  const exportCsvPath = '/gitlab-org/gitlab-test/-/issues/export_csv';
  const issuableCount = 10;

  function createComponent(injectedProperties = {}, props = {}) {
    glModalDirective = jest.fn();
    return mountExtended(CsvImportExportButtons, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      provide: {
        ...injectedProperties,
      },
      propsData: {
        exportCsvPath,
        issuableCount,
        ...props,
      },
    });
  }

  const findExportCsvButton = () => wrapper.findByTestId('export-as-csv-button');
  const findImportCsvButton = () => wrapper.findByTestId('import-from-csv-button');
  const findImportFromJiraLink = () => wrapper.findByTestId('import-from-jira-link');
  const findExportCsvModal = () => wrapper.findComponent(CsvExportModal);
  const findImportCsvModal = () => wrapper.findComponent(CsvImportModal);

  describe('template', () => {
    describe('when the showExportButton=true', () => {
      beforeEach(() => {
        wrapper = createComponent({ showExportButton: true });
      });

      it('displays the export button', () => {
        expect(findExportCsvButton().exists()).toBe(true);
      });

      it('renders the export modal', () => {
        expect(findExportCsvModal().props()).toMatchObject({ exportCsvPath, issuableCount });
      });

      it('opens the export modal', () => {
        findExportCsvButton().trigger('click');

        expect(glModalDirective).toHaveBeenCalled();
      });
    });

    describe('when the showExportButton=false', () => {
      beforeEach(() => {
        wrapper = createComponent({ showExportButton: false });
      });

      it('does not display the export button', () => {
        expect(findExportCsvButton().exists()).toBe(false);
      });

      it('does not render the export modal', () => {
        expect(findExportCsvModal().exists()).toBe(false);
      });
    });

    describe('when the showImportButton=true', () => {
      it('renders the import csv menu item', () => {
        wrapper = createComponent({ showImportButton: true });

        expect(findImportCsvButton().exists()).toBe(true);
      });

      it('renders the import modal', () => {
        wrapper = createComponent({ showImportButton: true });

        expect(findImportCsvModal().exists()).toBe(true);
      });

      it('opens the import modal', () => {
        wrapper = createComponent({ showImportButton: true });

        findImportCsvButton().trigger('click');

        expect(glModalDirective).toHaveBeenCalled();
      });

      describe('import from jira link', () => {
        const projectImportJiraPath = 'gitlab-org/gitlab-test/-/import/jira';

        describe('when canEdit=true', () => {
          beforeEach(() => {
            wrapper = createComponent({
              showImportButton: true,
              canEdit: true,
              projectImportJiraPath,
            });
          });

          it('renders the import dropdown item', () => {
            expect(findImportFromJiraLink().exists()).toBe(true);
          });

          it('passes the proper path to the link', () => {
            expect(findImportFromJiraLink().props('item').href).toBe(projectImportJiraPath);
          });
        });

        describe('when canEdit=false', () => {
          beforeEach(() => {
            wrapper = createComponent({ showImportButton: true, canEdit: false });
          });

          it('does not render the import dropdown item', () => {
            expect(findImportFromJiraLink().exists()).toBe(false);
          });
        });
      });
    });

    describe('when the showImportButton=false', () => {
      beforeEach(() => {
        wrapper = createComponent({ showImportButton: false });
      });

      it('does not render the import csv menu item', () => {
        expect(findImportCsvButton().exists()).toBe(false);
      });

      it('does not render the import modal', () => {
        expect(findImportCsvModal().exists()).toBe(false);
      });
    });
  });
});
