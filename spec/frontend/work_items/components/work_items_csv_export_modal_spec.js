import { GlModal, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { createAlert } from '~/alert';
import WorkItemsCsvExportModal from '~/work_items/components/work_items_csv_export_modal.vue';
import workItemsCsvExportMutation from '~/work_items/graphql/work_items_csv_export.mutation.graphql';
import { workItemsCsvExportResponse, workItemsCsvExportFailureResponse } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemsCsvExportModal', () => {
  let wrapper;
  const workItemCount = 10;

  function createComponent(options = {}) {
    const {
      injectedProperties = {},
      props = {},
      workItemsCsvExportHandler = jest.fn().mockResolvedValue(workItemsCsvExportResponse),
    } = options;

    return mount(WorkItemsCsvExportModal, {
      apolloProvider: createMockApollo([[workItemsCsvExportMutation, workItemsCsvExportHandler]]),
      propsData: {
        modalId: 'csv-export-modal',
        workItemCount,
        ...props,
      },
      provide: {
        userExportEmail: 'admin@example.com',
        glFeatures: {
          workItemPlanningView: true,
        },
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
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the cancel button', () => {
      expect(findModal().props('actionCancel')).toEqual({ text: 'Cancel' });
    });

    describe('email info text', () => {
      it('displays the proper email', () => {
        const email = 'admin@example.com';
        wrapper = createComponent({ injectedProperties: { userExportEmail: email } });
        expect(findModal().text()).toContain(
          `The CSV export will be created in the background. Once finished, it will be sent to ${email} in an attachment.`,
        );
      });
    });

    describe('when workItemPlanningView is enabled', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('displays the modal title "Export work items"', () => {
        expect(findModal().props('title')).toBe('Export work items');
      });

      it('displays the primary button with title "Export work items"', () => {
        expect(findModal().props('actionPrimary')).toMatchObject({
          text: 'Export work items',
          attributes: {
            variant: 'confirm',
            'data-testid': 'export-work-items-button',
            'data-track-action': 'click_button',
            'data-track-label': 'export_work_items_csv',
          },
        });
      });

      it('displays work item count text', () => {
        expect(wrapper.text()).toContain(`${workItemCount} work items selected`);
        expect(findIcon().exists()).toBe(true);
      });
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

      it('displays the modal title "Export issues"', () => {
        expect(findModal().props('title')).toBe('Export issues');
      });

      it('displays the primary button with title "Export issues"', () => {
        expect(findModal().props('actionPrimary')).toMatchObject({
          text: 'Export issues',
          attributes: {
            variant: 'confirm',
            'data-testid': 'export-work-items-button',
            'data-track-action': 'click_button',
            'data-track-label': 'export_work_items_csv',
          },
        });
      });

      it('displays issue count text', () => {
        wrapper = createComponent({
          injectedProperties: {
            glFeatures: {
              workItemPlanningView: false,
            },
          },
        });
        expect(wrapper.text()).toContain(`${workItemCount} issues selected`);
        expect(findIcon().exists()).toBe(true);
      });
    });
  });

  describe('exportWorkItems', () => {
    it('exports successfully', async () => {
      const workItemsCsvExportHandler = jest.fn().mockResolvedValue(workItemsCsvExportResponse);
      const queryVariables = { projectPath: 'gitlab-org/gitlab', search: 'test' };
      wrapper = createComponent({
        workItemsCsvExportHandler,
        props: { queryVariables },
      });

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(workItemsCsvExportHandler).toHaveBeenCalledWith({
        input: queryVariables,
      });
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Your CSV export request has succeeded. The result will be emailed to email',
        variant: 'success',
      });
    });

    it('sets loading state during export', async () => {
      let resolveExport;
      const exportPromise = new Promise((resolve) => {
        resolveExport = resolve;
      });
      const workItemsCsvExportHandler = jest.fn().mockReturnValue(exportPromise);
      wrapper = createComponent({ workItemsCsvExportHandler });

      findModal().vm.$emit('primary');

      await nextTick();

      expect(findModal().props('actionPrimary').attributes.loading).toBe(true);

      resolveExport(workItemsCsvExportResponse);
      await waitForPromises();

      expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
    });

    describe('when export fails', () => {
      it('shows work items error message when workItemPlanningView is enabled', async () => {
        const workItemsCsvExportHandler = jest
          .fn()
          .mockRejectedValue(workItemsCsvExportFailureResponse);
        wrapper = createComponent({ workItemsCsvExportHandler });

        findModal().vm.$emit('primary');

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while exporting work items.',
        });
      });

      it('shows issues error message when workItemPlanningView is disabled', async () => {
        const workItemsCsvExportHandler = jest
          .fn()
          .mockRejectedValue(workItemsCsvExportFailureResponse);
        wrapper = createComponent({
          workItemsCsvExportHandler,
          injectedProperties: {
            glFeatures: {
              workItemPlanningView: false,
            },
          },
        });

        findModal().vm.$emit('primary');

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while exporting issues.',
        });
      });
    });
  });
});
