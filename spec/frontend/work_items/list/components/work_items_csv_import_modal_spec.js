import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import WorkItemsCsvImportModal from '~/work_items/list/components/work_items_csv_import_modal.vue';
import workItemsCsvImportMutation from '~/work_items/list/graphql/work_items_csv_import.mutation.graphql';

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
  const findFileError = () => wrapper.find('.invalid-feedback');

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
  });

  describe('importWorkItems', () => {
    it('keeps the modal open and shows an inline error when no file is selected', async () => {
      wrapper = createComponent();
      const event = { preventDefault: jest.fn() };

      findModal().vm.$emit('primary', event);
      await nextTick();

      expect(event.preventDefault).toHaveBeenCalled();
      expect(findFileError().text()).toBe('Please select a file to import.');
      expect(findFileError().classes()).toContain('!gl-block');
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('clears the inline error when a file is selected', async () => {
      wrapper = createComponent();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();

      const file = new File(['content'], 'test.csv', { type: 'text/csv' });
      const fileInput = findFileInput();
      Object.defineProperty(fileInput.element, 'files', {
        value: [file],
        configurable: true,
      });
      await fileInput.trigger('change');

      expect(findFileError().classes()).not.toContain('!gl-block');
    });

    it('clears the inline error when the modal is dismissed', async () => {
      wrapper = createComponent();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();

      expect(findFileError().classes()).toContain('!gl-block');

      findModal().vm.$emit('hidden');
      await nextTick();

      expect(findFileError().classes()).not.toContain('!gl-block');
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
