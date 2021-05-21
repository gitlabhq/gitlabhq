import { GlButton, GlDropdown } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CsvExportModal from '~/issuable/components/csv_export_modal.vue';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import CsvImportModal from '~/issuable/components/csv_import_modal.vue';

describe('CsvImportExportButtons', () => {
  let wrapper;
  let glModalDirective;

  const exportCsvPath = '/gitlab-org/gitlab-test/-/issues/export_csv';
  const issuableCount = 10;

  function createComponent(injectedProperties = {}) {
    glModalDirective = jest.fn();
    return mountExtended(CsvImportExportButtons, {
      directives: {
        GlTooltip: createMockDirective(),
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
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findExportCsvButton = () => wrapper.findComponent(GlButton);
  const findImportDropdown = () => wrapper.findComponent(GlDropdown);
  const findImportCsvButton = () => wrapper.findByRole('menuitem', { name: 'Import CSV' });
  const findImportFromJiraLink = () => wrapper.findByRole('menuitem', { name: 'Import from Jira' });
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

      it('export button has a tooltip', () => {
        const tooltip = getBinding(findExportCsvButton().element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Export as CSV');
      });

      it('renders the export modal', () => {
        expect(findExportCsvModal().props()).toMatchObject({ exportCsvPath, issuableCount });
      });

      it('opens the export modal', () => {
        findExportCsvButton().trigger('click');

        expect(glModalDirective).toHaveBeenCalledWith(wrapper.vm.exportModalId);
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
      beforeEach(() => {
        wrapper = createComponent({ showImportButton: true });
      });

      it('displays the import dropdown', () => {
        expect(findImportDropdown().exists()).toBe(true);
      });

      it('renders the import csv menu item', () => {
        expect(findImportCsvButton().exists()).toBe(true);
      });

      describe('when showLabel=false', () => {
        beforeEach(() => {
          wrapper = createComponent({ showImportButton: true, showLabel: false });
        });

        it('hides button text', () => {
          expect(findImportDropdown().props()).toMatchObject({
            text: 'Import issues',
            textSrOnly: true,
          });
        });

        it('import button has a tooltip', () => {
          const tooltip = getBinding(findImportDropdown().element, 'gl-tooltip');

          expect(tooltip).toBeDefined();
          expect(tooltip.value).toBe('Import issues');
        });
      });

      describe('when showLabel=true', () => {
        beforeEach(() => {
          wrapper = createComponent({ showImportButton: true, showLabel: true });
        });

        it('displays a button text', () => {
          expect(findImportDropdown().props()).toMatchObject({
            text: 'Import issues',
            textSrOnly: false,
          });
        });

        it('import button has no tooltip', () => {
          const tooltip = getBinding(findImportDropdown().element, 'gl-tooltip');

          expect(tooltip.value).toBe(null);
        });
      });

      it('renders the import modal', () => {
        expect(findImportCsvModal().exists()).toBe(true);
      });

      it('opens the import modal', () => {
        findImportCsvButton().trigger('click');

        expect(glModalDirective).toHaveBeenCalledWith(wrapper.vm.importModalId);
      });

      describe('import from jira link', () => {
        const projectImportJiraPath = 'gitlab-org/gitlab-test/-/import/jira';

        beforeEach(() => {
          wrapper = createComponent({
            showImportButton: true,
            canEdit: true,
            projectImportJiraPath,
          });
        });

        describe('when canEdit=true', () => {
          it('renders the import dropdown item', () => {
            expect(findImportFromJiraLink().exists()).toBe(true);
          });

          it('passes the proper path to the link', () => {
            expect(findImportFromJiraLink().attributes('href')).toBe(projectImportJiraPath);
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

      it('does not display the import dropdown', () => {
        expect(findImportDropdown().exists()).toBe(false);
      });

      it('does not render the import modal', () => {
        expect(findImportCsvModal().exists()).toBe(false);
      });
    });
  });
});
