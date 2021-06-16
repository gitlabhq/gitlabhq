import { GlModal, GlIcon, GlButton } from '@gitlab/ui';
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
        issuableType: 'issues',
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

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findButton = () => wrapper.findComponent(GlButton);

  describe('template', () => {
    describe.each`
      issuableType        | modalTitle
      ${'issues'}         | ${'Export issues'}
      ${'merge-requests'} | ${'Export merge requests'}
    `('with the issuableType "$issuableType"', ({ issuableType, modalTitle }) => {
      beforeEach(() => {
        wrapper = createComponent({ injectedProperties: { issuableType } });
      });

      it('displays the modal title "$modalTitle"', () => {
        expect(findModal().text()).toContain(modalTitle);
      });

      it('displays the button with title "$modalTitle"', () => {
        expect(findButton().text()).toBe(modalTitle);
      });
    });

    describe('issuable count info text', () => {
      it('displays the info text when issuableCount is > -1', () => {
        wrapper = createComponent({ props: { issuableCount: 10 } });
        expect(wrapper.text()).toContain('10 issues selected');
        expect(findIcon().exists()).toBe(true);
      });

      it("doesn't display the info text when issuableCount is -1", () => {
        wrapper = createComponent({ props: { issuableCount: -1 } });
        expect(wrapper.text()).not.toContain('issues selected');
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

    describe('primary button', () => {
      it('passes the exportCsvPath to the button', () => {
        const exportCsvPath = '/gitlab-org/gitlab-test/-/issues/export_csv';
        wrapper = createComponent({ props: { exportCsvPath } });
        expect(findButton().attributes('href')).toBe(exportCsvPath);
      });
    });
  });
});
