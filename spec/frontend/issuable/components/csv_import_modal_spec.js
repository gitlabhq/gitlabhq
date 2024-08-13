import { GlModal } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CsvImportModal from '~/issuable/components/csv_import_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('CsvImportModal', () => {
  let wrapper;
  let formSubmitSpy;

  function createComponent(options = {}) {
    const { injectedProperties = {}, props = {} } = options;
    return mountExtended(CsvImportModal, {
      propsData: {
        modalId: 'csv-import-modal',
        ...props,
      },
      provide: {
        ...injectedProperties,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  }

  beforeEach(() => {
    formSubmitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');
  const findFileInput = () => wrapper.findByLabelText('Upload CSV file');
  const findAuthenticityToken = () => new FormData(findForm().element).get('authenticity_token');

  describe('template', () => {
    it('passes correct title props to modal', () => {
      wrapper = createComponent();
      expect(findModal().props('title')).toContain('Import issues');
    });

    it('displays a note about the maximum allowed file size', () => {
      const maxAttachmentSize = 500;
      wrapper = createComponent({ injectedProperties: { maxAttachmentSize } });
      expect(findModal().text()).toContain(`The maximum file size allowed is ${maxAttachmentSize}`);
    });

    describe('form', () => {
      const importCsvIssuesPath = 'gitlab-org/gitlab-test/-/issues/import_csv';

      beforeEach(() => {
        wrapper = createComponent({ injectedProperties: { importCsvIssuesPath } });
      });

      it('displays the form with the correct action and inputs', () => {
        expect(findForm().exists()).toBe(true);
        expect(findForm().attributes('action')).toBe(importCsvIssuesPath);
        expect(findAuthenticityToken()).toBe('mock-csrf-token');
        expect(findFileInput().exists()).toBe(true);
      });

      it('displays the correct primary button action text', () => {
        expect(findModal().props('actionPrimary')).toEqual({ text: 'Import issues' });
      });

      it('submits the form when the primary action is clicked', () => {
        findModal().vm.$emit('primary');

        expect(formSubmitSpy).toHaveBeenCalled();
      });

      it('displays the cancel button', () => {
        expect(findModal().props('actionCancel')).toEqual({ text: 'Cancel' });
      });
    });
  });
});
