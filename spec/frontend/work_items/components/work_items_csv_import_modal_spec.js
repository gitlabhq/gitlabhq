import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import WorkItemsCsvImportModal from '~/work_items/components/work_items_csv_import_modal.vue';
import workItemsCsvImportMutation from '~/work_items/graphql/work_items_csv_import.mutation.graphql';

jest.mock('~/alert');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

Vue.use(VueApollo);

describe('WorkItemsCsvImportModal', () => {
  let wrapper;

  const mockSuccessResponse = {
    data: {
      workItemsCsvImport: {
        message: 'Import started successfully',
        errors: [],
      },
    },
  };
  const workItemsCsvImportSuccessHandler = jest.fn().mockResolvedValue(mockSuccessResponse);
  const workItemsCsvImportNetworkErrorHandler = jest
    .fn()
    .mockRejectedValue(new Error('Network error'));

  function createComponent(options = {}) {
    const {
      injectedProperties = {},
      props = {},
      workItemsCsvImportHandler = jest.fn().mockResolvedValue(mockSuccessResponse),
    } = options;

    return mountExtended(WorkItemsCsvImportModal, {
      apolloProvider: createMockApollo([[workItemsCsvImportMutation, workItemsCsvImportHandler]]),
      propsData: {
        modalId: 'csv-import-modal',
        fullPath: 'group/project',
        ...props,
      },
      provide: {
        maxAttachmentSize: '10MB',
        glFeatures: {
          workItemPlanningView: true,
        },
        ...injectedProperties,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  }

  const findModal = () => wrapper.findComponent(GlModal);
  const findFileInput = () => wrapper.findByLabelText('Upload CSV file');

  describe('template', () => {
    it('passes correct title props to modal', () => {
      wrapper = createComponent();
      expect(findModal().props('title')).toContain('Import work items');
    });

    it('displays a note about the maximum allowed file size', () => {
      const maxAttachmentSize = '500MB';
      wrapper = createComponent({ injectedProperties: { maxAttachmentSize } });
      expect(findModal().text()).toContain(`The maximum file size allowed is ${maxAttachmentSize}`);
    });

    it('displays the correct primary button action text', () => {
      wrapper = createComponent();
      expect(findModal().props('actionPrimary')).toMatchObject({
        text: 'Import work items',
        attributes: {
          'data-testid': 'import-work-items-button',
        },
      });
    });

    it('displays the cancel button', () => {
      wrapper = createComponent();
      expect(findModal().props('actionCancel')).toEqual({ text: 'Cancel' });
    });

    it('displays the file input', () => {
      wrapper = createComponent();
      expect(findFileInput().exists()).toBe(true);
      expect(findFileInput().attributes('accept')).toBe('.csv,text/csv');
    });

    describe('when workItemPlanningView is disabled', () => {
      beforeEach(() => {
        wrapper = createComponent({
          injectedProperties: {
            glFeatures: {
              workItemPlanningView: false,
            },
          },
        });
      });

      it('displays issues text in modal title', () => {
        expect(findModal().props('title')).toBe('Import issues');
      });

      it('displays issues text in primary button', () => {
        expect(findModal().props('actionPrimary').text).toBe('Import issues');
      });
    });
  });

  describe('importWorkItems', () => {
    it('shows error when no file is selected', async () => {
      wrapper = createComponent();

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Please select a file to import.',
      });
    });

    it('imports successfully with selected file', async () => {
      wrapper = createComponent({ workItemsCsvImportHandler: workItemsCsvImportSuccessHandler });

      const file = new File(['content'], 'test.csv', { type: 'text/csv' });
      const fileInput = findFileInput();
      Object.defineProperty(fileInput.element, 'files', {
        value: [file],
        configurable: true,
      });
      await fileInput.trigger('change');

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(workItemsCsvImportSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectPath: 'group/project',
          file,
        },
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Import started successfully',
        variant: 'success',
      });
    });

    it('shows generic error message when import fails', async () => {
      wrapper = createComponent({
        workItemsCsvImportHandler: workItemsCsvImportNetworkErrorHandler,
      });

      const file = new File(['content'], 'test.csv', { type: 'text/csv' });
      const fileInput = findFileInput();
      Object.defineProperty(fileInput.element, 'files', {
        value: [file],
        configurable: true,
      });
      await fileInput.trigger('change');

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while importing work items.',
      });
    });
  });
});
