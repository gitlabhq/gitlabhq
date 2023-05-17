import { GlTokenSelector, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import labelSearchQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import workItemLabelsSubscription from 'ee_else_ce/work_items/graphql/work_item_labels.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import { i18n, I18N_WORK_ITEM_ERROR_FETCHING_LABELS } from '~/work_items/constants';
import {
  projectLabelsResponse,
  mockLabels,
  workItemByIidResponseFactory,
  updateWorkItemMutationResponse,
  workItemLabelsSubscriptionResponse,
} from '../mock_data';

Vue.use(VueApollo);

const workItemId = 'gid://gitlab/WorkItem/1';

describe('WorkItemLabels component', () => {
  let wrapper;

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findLabelsTitle = () => wrapper.findByTestId('labels-title');

  const workItemQuerySuccess = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ labels: null }));
  const successSearchQueryHandler = jest.fn().mockResolvedValue(projectLabelsResponse);
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);
  const subscriptionHandler = jest.fn().mockResolvedValue(workItemLabelsSubscriptionResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const createComponent = ({
    canUpdate = true,
    workItemQueryHandler = workItemQuerySuccess,
    searchQueryHandler = successSearchQueryHandler,
    updateWorkItemMutationHandler = successUpdateWorkItemMutationHandler,
    workItemIid = '1',
  } = {}) => {
    wrapper = mountExtended(WorkItemLabels, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [labelSearchQuery, searchQueryHandler],
        [updateWorkItemMutation, updateWorkItemMutationHandler],
        [workItemLabelsSubscription, subscriptionHandler],
      ]),
      provide: {
        fullPath: 'test-project-path',
      },
      propsData: {
        workItemId,
        workItemIid,
        canUpdate,
      },
      attachTo: document.body,
    });
  };

  it('has a label', () => {
    createComponent();

    expect(findTokenSelector().props('ariaLabelledby')).toEqual(findLabelsTitle().attributes('id'));
  });

  it('focuses token selector on token selector input event', async () => {
    createComponent();
    findTokenSelector().vm.$emit('input', [mockLabels[0]]);
    await waitForPromises();

    expect(findEmptyState().exists()).toBe(false);
    expect(findTokenSelector().element.contains(document.activeElement)).toBe(true);
  });

  it('does not start search by default', () => {
    createComponent();

    expect(findTokenSelector().props('loading')).toBe(false);
    expect(findTokenSelector().props('dropdownItems')).toEqual([]);
  });

  it('starts search on hovering for more than 250ms', async () => {
    createComponent();
    findTokenSelector().trigger('mouseover');
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(true);
  });

  it('starts search on focusing token selector', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(true);
  });

  it('does not start searching if token-selector was hovered for less than 250ms', async () => {
    createComponent();
    findTokenSelector().trigger('mouseover');
    jest.advanceTimersByTime(100);
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(false);
  });

  it('does not start searching if cursor was moved out from token selector before 250ms passed', async () => {
    createComponent();
    findTokenSelector().trigger('mouseover');
    jest.advanceTimersByTime(100);

    findTokenSelector().trigger('mouseout');
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await nextTick();

    expect(findTokenSelector().props('loading')).toBe(false);
  });

  it('shows skeleton loader on dropdown when loading', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('shows list in dropdown when loaded', async () => {
    createComponent();
    findTokenSelector().vm.$emit('focus');
    await nextTick();

    expect(findSkeletonLoader().exists()).toBe(true);

    await waitForPromises();

    expect(findSkeletonLoader().exists()).toBe(false);
    expect(findTokenSelector().props('dropdownItems')).toHaveLength(2);
  });

  it.each([true, false])(
    'passes canUpdate=%s prop to view-only of token-selector',
    async (canUpdate) => {
      createComponent({ canUpdate });

      await waitForPromises();

      expect(findTokenSelector().props('viewOnly')).toBe(!canUpdate);
    },
  );

  it('emits error event if search query fails', async () => {
    createComponent({ searchQueryHandler: errorHandler });
    findTokenSelector().vm.$emit('focus');
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[I18N_WORK_ITEM_ERROR_FETCHING_LABELS]]);
  });

  it('should search for with correct key after text input', async () => {
    const searchKey = 'Hello';

    createComponent();
    findTokenSelector().vm.$emit('focus');
    findTokenSelector().vm.$emit('text-input', searchKey);
    await waitForPromises();

    expect(successSearchQueryHandler).toHaveBeenCalledWith(
      expect.objectContaining({ searchTerm: searchKey }),
    );
  });

  it('adds new labels to the end', async () => {
    const response = workItemByIidResponseFactory({ labels: [mockLabels[1]] });
    const workItemQueryHandler = jest.fn().mockResolvedValue(response);
    createComponent({
      workItemQueryHandler,
      updateWorkItemMutationHandler: successUpdateWorkItemMutationHandler,
    });
    await waitForPromises();

    findTokenSelector().vm.$emit('input', [mockLabels[0]]);
    await waitForPromises();

    const labels = findTokenSelector().props('selectedTokens');
    expect(labels[0]).toMatchObject(mockLabels[1]);
    expect(labels[1]).toMatchObject(mockLabels[0]);
  });

  describe('when clicking outside the token selector', () => {
    it('calls a mutation with correct variables', () => {
      createComponent();

      findTokenSelector().vm.$emit('input', [mockLabels[0]]);
      findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));

      expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith({
        input: {
          labelsWidget: { addLabelIds: [mockLabels[0].id], removeLabelIds: [] },
          id: 'gid://gitlab/WorkItem/1',
        },
      });
    });

    it('emits an error and resets labels if mutation was rejected', async () => {
      createComponent({ updateWorkItemMutationHandler: errorHandler });

      await waitForPromises();

      const initialLabels = findTokenSelector().props('selectedTokens');

      findTokenSelector().vm.$emit('input', [mockLabels[0]]);
      findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));

      await waitForPromises();

      const updatedLabels = findTokenSelector().props('selectedTokens');

      expect(wrapper.emitted('error')).toEqual([[i18n.updateError]]);
      expect(updatedLabels).toEqual(initialLabels);
    });

    it('does not make server request if no labels added or removed', async () => {
      const updateWorkItemMutationHandler = jest
        .fn()
        .mockResolvedValue(updateWorkItemMutationResponse);

      createComponent({ updateWorkItemMutationHandler });

      await waitForPromises();

      findTokenSelector().vm.$emit('input', []);
      findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));

      await waitForPromises();

      expect(updateWorkItemMutationHandler).not.toHaveBeenCalled();
    });

    it('has a subscription', async () => {
      createComponent();

      await waitForPromises();

      expect(subscriptionHandler).toHaveBeenCalledWith({
        issuableId: workItemId,
      });
    });
  });

  it('calls the work item query', async () => {
    createComponent();
    await waitForPromises();

    expect(workItemQuerySuccess).toHaveBeenCalled();
  });

  it('skips calling the work item query when missing workItemIid', async () => {
    createComponent({ workItemIid: null });
    await waitForPromises();

    expect(workItemQuerySuccess).not.toHaveBeenCalled();
  });
});
