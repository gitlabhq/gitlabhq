import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlAlert, GlLink, GlFormInput } from '@gitlab/ui';
import setIssueTimeEstimateWithErrors from 'test_fixtures/graphql/issue_set_time_estimate_with_errors.json';
import setIssueTimeEstimateWithoutErrors from 'test_fixtures/graphql/issue_set_time_estimate_without_errors.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import SetTimeEstimateForm from '~/sidebar/components/time_tracking/set_time_estimate_form.vue';
import issueSetTimeEstimateMutation from '~/sidebar/queries/issue_set_time_estimate.mutation.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse } from 'jest/work_items/mock_data';

const mockProjectFullPath = 'group/project';
const mockMutationErrorMessage = setIssueTimeEstimateWithErrors.errors[0].message;
const mockIssuableIid = '1';
const mockMutationTimeEstimateInHumanReadableFormat = '1d 2h';
const mockTimeTrackingData = {
  timeEstimate: 3600,
  humanTimeEstimate: '1h',
};

const resolvedMutationWithoutErrorsMock = jest
  .fn()
  .mockResolvedValue(setIssueTimeEstimateWithoutErrors);
const resolvedMutationWithErrorsMock = jest.fn().mockResolvedValue(setIssueTimeEstimateWithErrors);

const rejectedMutationMock = jest.fn().mockRejectedValue();
const modalCloseMock = jest.fn();

const updateWorkItemMutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

describe('Set Time Estimate Form', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalTitle = () => findModal().props('title');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDocsLink = () => wrapper.findComponent(GlLink);
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findSaveButton = () => findModal().props('actionPrimary');
  const findSaveButtonLoadingState = () => findSaveButton().attributes.loading;
  const findSaveButtonDisabledState = () => findSaveButton().attributes.disabled;
  const findResetButton = () => findModal().props('actionSecondary');
  const findResetButtonLoadingState = () => findResetButton().attributes.loading;
  const findResetButtonDisabledState = () => findResetButton().attributes.disabled;
  const findTimeEstiamteInput = () => wrapper.findByTestId('time-estimate');

  const triggerSave = () => {
    const mockEvent = { preventDefault: jest.fn() };
    findModal().vm.$emit('primary', mockEvent);
  };

  const triggerReset = () => {
    const mockEvent = { preventDefault: jest.fn() };
    findModal().vm.$emit('secondary', mockEvent);
  };

  const mountComponent = async ({
    timeTracking = mockTimeTrackingData,
    data,
    props,
    providedProps,
    mutationResolverMock = resolvedMutationWithoutErrorsMock,
  } = {}) => {
    wrapper = shallowMountExtended(SetTimeEstimateForm, {
      data() {
        return {
          ...data,
        };
      },
      provide: {
        issuableType: 'issue',
        ...providedProps,
      },
      propsData: {
        issuableIid: mockIssuableIid,
        fullPath: mockProjectFullPath,
        timeTracking,
        ...props,
      },
      apolloProvider: createMockApollo([
        [issueSetTimeEstimateMutation, mutationResolverMock],
        [updateWorkItemMutation, updateWorkItemMutationHandler],
      ]),
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: { close: modalCloseMock },
        }),
      },
    });

    findModal().vm.$emit('show');
    await nextTick();
  };

  describe('modal title', () => {
    it('is `Set time estimate` when the current estimate is 0', async () => {
      await mountComponent({
        timeTracking: { timeEstimate: 0, humanTimeEstimate: '0h' },
        mutationResolverMock: resolvedMutationWithoutErrorsMock,
      });

      expect(findModalTitle()).toBe('Set time estimate');
    });

    it('is `Edit time estimate` when the current estimate is not 0', async () => {
      await mountComponent();

      expect(findModalTitle()).toBe('Edit time estimate');
    });
  });

  describe('modal', () => {
    it('shows the provided human time estimate from the timeTracking prop', async () => {
      await mountComponent();

      expect(findTimeEstiamteInput().attributes('value')).toBe(
        mockTimeTrackingData.humanTimeEstimate,
      );
    });
  });

  describe('save button', () => {
    it('is not loading by default', async () => {
      await mountComponent();

      expect(findSaveButtonLoadingState()).toBe(false);
    });

    it('is disabled and not loading when time estimate is empty', async () => {
      await mountComponent({ data: { timeEstimate: '' } });

      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(true);
    });

    it('is enabled and not loading when time estimate is not empty', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
      });

      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('is disabled and loading when the the save button is clicked', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
      });

      triggerSave();

      await nextTick();

      expect(findSaveButtonLoadingState()).toBe(true);
      expect(findSaveButtonDisabledState()).toBe(true);
    });

    it('is disabled and loading when the the reset button is clicked', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
      });

      triggerReset();

      await nextTick();

      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(true);
    });

    it('is enabled and not loading the when the save button is clicked and the mutation had errors', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
        mutationResolverMock: rejectedMutationMock,
      });

      triggerSave();

      await waitForPromises();

      expect(rejectedMutationMock).toHaveBeenCalledWith({
        input: {
          projectPath: mockProjectFullPath,
          iid: mockIssuableIid,
          timeEstimate: mockMutationTimeEstimateInHumanReadableFormat,
        },
      });
      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('is enabled and not loading the when save button is clicked and the mutation returns errors', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
        mutationResolverMock: resolvedMutationWithErrorsMock,
      });

      triggerSave();

      await waitForPromises();

      expect(resolvedMutationWithErrorsMock).toHaveBeenCalledWith({
        input: {
          projectPath: mockProjectFullPath,
          iid: mockIssuableIid,
          timeEstimate: mockMutationTimeEstimateInHumanReadableFormat,
        },
      });
      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('closes the modal after submission and the mutation did not return any error', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
        mutationResolverMock: resolvedMutationWithoutErrorsMock,
      });

      triggerSave();

      await waitForPromises();

      expect(resolvedMutationWithoutErrorsMock).toHaveBeenCalledWith({
        input: {
          projectPath: mockProjectFullPath,
          iid: mockIssuableIid,
          timeEstimate: mockMutationTimeEstimateInHumanReadableFormat,
        },
      });
      expect(modalCloseMock).toHaveBeenCalled();
    });
  });

  describe('reset button', () => {
    it('is not visible when the current estimate is 0', async () => {
      await mountComponent({
        timeTracking: { timeEstimate: 0, humanTimeEstimate: '0h' },
        mutationResolverMock: resolvedMutationWithoutErrorsMock,
      });

      expect(findResetButton()).toBe(null);
    });

    it('is enabled and not loading even if time estimate is empty', async () => {
      await mountComponent({ data: { timeEstimate: '' } });

      expect(findResetButtonLoadingState()).toBe(false);
      expect(findResetButtonDisabledState()).toBe(false);
    });

    it('is enabled and not loading when time estimate is not empty', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
      });

      expect(findResetButtonLoadingState()).toBe(false);
      expect(findResetButtonDisabledState()).toBe(false);
    });

    it('is disabled and loading when the the reset button is clicked', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
      });

      triggerReset();

      await nextTick();

      expect(findResetButtonLoadingState()).toBe(true);
      expect(findResetButtonDisabledState()).toBe(true);
    });

    it('is disabled and loading when the the save button is clicked', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
      });

      triggerSave();

      await nextTick();

      expect(findResetButtonLoadingState()).toBe(false);
      expect(findResetButtonDisabledState()).toBe(true);
    });

    it('is enabled and not loading the when the reset button is clicked and the mutation had errors', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
        mutationResolverMock: rejectedMutationMock,
      });

      triggerReset();

      await waitForPromises();

      expect(rejectedMutationMock).toHaveBeenCalledWith({
        input: {
          projectPath: mockProjectFullPath,
          iid: mockIssuableIid,
          timeEstimate: '0',
        },
      });
      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('is enabled and not loading the when reset button is clicked and the mutation returns errors', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
        mutationResolverMock: resolvedMutationWithErrorsMock,
      });

      triggerReset();

      await waitForPromises();

      expect(resolvedMutationWithErrorsMock).toHaveBeenCalledWith({
        input: {
          projectPath: mockProjectFullPath,
          iid: mockIssuableIid,
          timeEstimate: '0',
        },
      });
      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('closes the modal after submission and the mutation did not return any error', async () => {
      await mountComponent({
        data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
        mutationResolverMock: resolvedMutationWithoutErrorsMock,
      });

      triggerReset();

      await waitForPromises();
      await nextTick();

      expect(resolvedMutationWithoutErrorsMock).toHaveBeenCalledWith({
        input: {
          projectPath: mockProjectFullPath,
          iid: mockIssuableIid,
          timeEstimate: '0',
        },
      });
      expect(modalCloseMock).toHaveBeenCalled();
    });
  });

  describe('alert', () => {
    it('is hidden by default', async () => {
      await mountComponent();

      expect(findAlert().exists()).toBe(false);
    });

    describe('when saving a change', () => {
      it('shows an error if the submission fails with a handled error', async () => {
        await mountComponent({
          data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
          mutationResolverMock: resolvedMutationWithErrorsMock,
        });

        triggerSave();

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(mockMutationErrorMessage);
      });

      it('shows an error if the submission fails with an unhandled error', async () => {
        await mountComponent({
          data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
          mutationResolverMock: rejectedMutationMock,
        });

        triggerSave();

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe('An error occurred while saving the time estimate.');
      });
    });

    describe('when resetting the time estimate', () => {
      it('shows an error if the submission fails with a handled error', async () => {
        await mountComponent({
          data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
          mutationResolverMock: resolvedMutationWithErrorsMock,
        });

        triggerReset();

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(mockMutationErrorMessage);
      });

      it('shows an error if the submission fails with an unhandled error', async () => {
        await mountComponent({
          data: { timeEstimate: mockMutationTimeEstimateInHumanReadableFormat },
          mutationResolverMock: rejectedMutationMock,
        });

        triggerReset();

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe('An error occurred while saving the time estimate.');
      });
    });
  });

  describe('docs link message', () => {
    it('is present', async () => {
      await mountComponent();

      expect(findDocsLink().text()).toBe('How do I estimate and track time?');
      expect(findDocsLink().attributes('href')).toBe('/help/user/project/time_tracking.md');
    });
  });

  describe('with work item task', () => {
    beforeEach(() => {
      mountComponent({
        props: { workItemId: 'gid://gitlab/WorkItem/1', workItemType: 'Task' },
        providedProps: { issuableType: null },
      });
    });

    it('mentions the correct work item type', () => {
      expect(wrapper.text()).toContain('Set estimated time to complete this task.');
    });

    it('calls mutation to update work item when setting estimate', async () => {
      findGlFormInput().vm.$emit('input', '2d');
      triggerSave();
      await waitForPromises();

      expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          timeTrackingWidget: {
            timeEstimate: '2d',
          },
        },
      });
    });
  });
});
