import { GlModal, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { createAlert } from '~/alert';
import CsvExportModal from '~/merge_requests/list/components/csv_export_modal.vue';
import exportMergeRequestsCsvMutation from '~/merge_requests/list/queries/project/export_merge_requests_csv.mutation.graphql';

jest.mock('~/alert');

Vue.use(VueApollo);

const exportVariables = {
  fullPath: 'group/project',
  state: 'merged',
  mergeUser: 'cleveland',
  targetBranches: ['main'],
};

const successResponse = {
  data: {
    mergeRequestsCsvExport: {
      message: 'Your CSV export request has succeeded.',
      errors: [],
    },
  },
};

describe('CsvExportModal', () => {
  let wrapper;
  let exportHandler;

  function createComponent(options = {}) {
    const { injectedProperties = {}, props = {}, handler = jest.fn() } = options;
    exportHandler = handler;

    return mount(CsvExportModal, {
      apolloProvider: createMockApollo([[exportMergeRequestsCsvMutation, exportHandler]]),
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

  describe('when the merge_requests_csv_export_graphql feature flag is enabled', () => {
    const createGraphqlComponent = ({ handler, injectedProperties = {} } = {}) =>
      createComponent({
        handler,
        props: { exportVariables },
        injectedProperties: {
          issuableType: 'merge_request',
          exportMergeRequestsCsvMutation,
          glFeatures: { mergeRequestsCsvExportGraphql: true },
          ...injectedProperties,
        },
      });

    it('does not post to the export path', () => {
      wrapper = createGraphqlComponent();

      const { attributes } = findModal().props('actionPrimary');

      expect(attributes.href).toBeUndefined();
      expect(attributes['data-method']).toBeUndefined();
    });

    it('exports with the list filters and shows the response message', async () => {
      wrapper = createGraphqlComponent({ handler: jest.fn().mockResolvedValue(successResponse) });

      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(exportHandler).toHaveBeenCalledWith(exportVariables);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Your CSV export request has succeeded.',
        variant: 'success',
      });
    });

    it.each`
      description                      | handler
      ${'the mutation returns errors'} | ${jest.fn().mockResolvedValue({ data: { mergeRequestsCsvExport: { message: null, errors: ['Failed'] } } })}
      ${'the request fails'}           | ${jest.fn().mockRejectedValue(new Error('Network error'))}
    `('shows an error alert when $description', async ({ handler }) => {
      wrapper = createGraphqlComponent({ handler });

      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while exporting merge requests.',
      });
    });

    it('posts to the export path when no export mutation is provided', () => {
      wrapper = createGraphqlComponent({
        injectedProperties: { exportMergeRequestsCsvMutation: null },
      });

      findModal().vm.$emit('primary');

      expect(findModal().props('actionPrimary').attributes.href).toBe('export/csv/path');
      expect(exportHandler).not.toHaveBeenCalled();
    });
  });

  describe('when the merge_requests_csv_export_graphql feature flag is disabled', () => {
    it('does not run the export mutation', async () => {
      wrapper = createComponent({
        props: { exportVariables },
        injectedProperties: { issuableType: 'merge_request', exportMergeRequestsCsvMutation },
      });

      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(exportHandler).not.toHaveBeenCalled();
    });
  });
});
