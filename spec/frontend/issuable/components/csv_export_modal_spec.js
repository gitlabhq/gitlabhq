import { GlModal, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import CsvExportModal from '~/issuable/components/csv_export_modal.vue';

describe('CsvExportModal', () => {
  let wrapper;

  function createComponent(options = {}) {
    const { injectedProperties = {}, props = {} } = options;
    return mount(CsvExportModal, {
      propsData: {
        modalId: 'csv-export-modal',
        exportCsvPath: 'export/csv/path',
        issuableCount: 1,
        ...props,
      },
      provide: {
        issuableType: 'issue',
        ...injectedProperties,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  }

  const findModal = () => wrapper.findComponent(GlModal);
  const findIcon = () => wrapper.findComponent(GlIcon);

  describe('template', () => {
    describe.each`
      issuableType       | modalTitle                 | dataTrackLabel
      ${'issue'}         | ${'Export issues'}         | ${'export_issues_csv'}
      ${'merge_request'} | ${'Export merge requests'} | ${'export_merge-requests_csv'}
    `('with the issuableType "$issuableType"', ({ issuableType, modalTitle, dataTrackLabel }) => {
      beforeEach(() => {
        wrapper = createComponent({ injectedProperties: { issuableType } });
      });

      it('displays the modal title "$modalTitle"', () => {
        expect(findModal().props('title')).toBe(modalTitle);
      });

      it('displays the primary button with title "$modalTitle" and href', () => {
        expect(findModal().props('actionPrimary')).toMatchObject({
          text: modalTitle,
          attributes: {
            href: 'export/csv/path',
            variant: 'confirm',
            'data-method': 'post',
            'data-testid': 'export-issues-button',
            'data-track-action': 'click_button',
            'data-track-label': dataTrackLabel,
          },
        });
      });

      it('displays the cancel button', () => {
        expect(findModal().props('actionCancel')).toEqual({ text: 'Cancel' });
      });
    });

    describe('issuable count info text', () => {
      it('displays the info text when issuableCount is > -1', () => {
        wrapper = createComponent({ props: { issuableCount: 10 } });
        expect(wrapper.text()).toContain('10 issues selected');
        expect(findIcon().exists()).toBe(true);
      });
    });

    describe('email info text', () => {
      it('displays the proper email', () => {
        const email = 'admin@example.com';
        wrapper = createComponent({ injectedProperties: { email } });
        expect(findModal().text()).toContain(
          `The CSV export will be created in the background. Once finished, it will be sent to ${email} in an attachment.`,
        );
      });
    });
  });
});
