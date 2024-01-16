import { GlCollapsibleListbox, GlListboxItem, GlSkeletonLoader, GlFormGroup } from '@gitlab/ui';

import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemMilestoneInline, {
  noMilestoneId,
} from '~/work_items/components/work_item_milestone_inline.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import {
  projectMilestonesResponse,
  projectMilestonesResponseWithNoMilestones,
  mockMilestoneWidgetResponse,
  updateWorkItemMutationErrorResponse,
  updateWorkItemMutationResponse,
} from '../mock_data';

describe('WorkItemMilestoneInline component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findNoMilestoneDropdownItem = () => wrapper.findByTestId('listbox-item-no-milestone-id');
  const findDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findDisabledTextSpan = () => wrapper.findByTestId('disabled-text');
  const findInputGroup = () => wrapper.findComponent(GlFormGroup);
  const findNoResultsText = () => wrapper.findByTestId('no-results-text');

  const successSearchQueryHandler = jest.fn().mockResolvedValue(projectMilestonesResponse);
  const successSearchWithNoMatchingMilestones = jest
    .fn()
    .mockResolvedValue(projectMilestonesResponseWithNoMilestones);
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);

  const showDropdown = () => findDropdown().vm.$emit('shown');
  const hideDropdown = () => findDropdown().vm.$emit('hide');

  const createComponent = ({
    canUpdate = true,
    milestone = mockMilestoneWidgetResponse,
    searchQueryHandler = successSearchQueryHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemMilestoneInline, {
      apolloProvider: createMockApollo([
        [projectMilestonesQuery, searchQueryHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        fullPath: 'full-path',
        canUpdate,
        workItemMilestone: milestone,
        workItemId,
        workItemType,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  it('has "Milestone" label', () => {
    createComponent();

    expect(findInputGroup().exists()).toBe(true);
    expect(findInputGroup().attributes('label')).toBe(WorkItemMilestoneInline.i18n.MILESTONE);
  });

  describe('Default text with canUpdate false and milestone value', () => {
    describe.each`
      description             | milestone                      | value
      ${'when no milestone'}  | ${null}                        | ${WorkItemMilestoneInline.i18n.NONE}
      ${'when milestone set'} | ${mockMilestoneWidgetResponse} | ${mockMilestoneWidgetResponse.title}
    `('$description', ({ milestone, value }) => {
      it(`has a value of "${value}"`, () => {
        createComponent({ canUpdate: false, milestone });

        expect(findDisabledTextSpan().text()).toBe(value);
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });

  describe('Default text value when canUpdate true and no milestone set', () => {
    it(`has a value of "Add to milestone"`, () => {
      createComponent({ canUpdate: true, milestone: null });

      expect(findDropdown().props('toggleText')).toBe(
        WorkItemMilestoneInline.i18n.MILESTONE_PLACEHOLDER,
      );
    });
  });

  describe('Dropdown search', () => {
    it('has the search box', () => {
      createComponent();

      expect(findDropdown().props('searchable')).toBe(true);
    });

    it('shows no matching results when no items', () => {
      createComponent({
        searchQueryHandler: successSearchWithNoMatchingMilestones,
      });

      expect(findNoResultsText().text()).toBe(WorkItemMilestoneInline.i18n.NO_MATCHING_RESULTS);
      expect(findDropdownItems()).toHaveLength(1);
    });
  });

  describe('Dropdown options', () => {
    beforeEach(() => {
      createComponent({ canUpdate: true });
    });

    it('calls successSearchQueryHandler with variables when dropdown is opened', async () => {
      showDropdown();
      await nextTick();

      expect(successSearchQueryHandler).toHaveBeenCalledWith({
        first: 20,
        fullPath: 'full-path',
        state: 'active',
        title: '',
      });
    });

    it('shows the skeleton loader when the items are being fetched on click', async () => {
      showDropdown();
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('shows the milestones in dropdown when the items have finished fetching', async () => {
      showDropdown();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findNoMilestoneDropdownItem().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(
        projectMilestonesResponse.data.workspace.attributes.nodes.length + 1,
      );
    });

    it('changes the milestone to null when clicked on no milestone', async () => {
      showDropdown();
      findDropdown().vm.$emit('select', noMilestoneId);

      hideDropdown();
      await nextTick();
      expect(findDropdown().props('loading')).toBe(true);

      await waitForPromises();
      expect(findDropdown().props()).toMatchObject({
        loading: false,
        toggleText: WorkItemMilestoneInline.i18n.MILESTONE_PLACEHOLDER,
        toggleClass: expect.arrayContaining(['gl-text-gray-500!']),
      });
    });

    it('changes the milestone to the selected milestone', async () => {
      const milestoneIndex = 1;
      /** the index is -1 since no matching results is also a dropdown item */
      const milestoneAtIndex =
        projectMilestonesResponse.data.workspace.attributes.nodes[milestoneIndex - 1];

      showDropdown();

      await waitForPromises();
      findDropdown().vm.$emit('select', milestoneAtIndex.id);

      hideDropdown();
      await waitForPromises();

      expect(findDropdown().props('toggleText')).toBe(milestoneAtIndex.title);
    });
  });

  describe('Error handlers', () => {
    it.each`
      errorType          | expectedErrorMessage                                                 | mockValue                              | resolveFunction
      ${'graphql error'} | ${'Something went wrong while updating the task. Please try again.'} | ${updateWorkItemMutationErrorResponse} | ${'mockResolvedValue'}
      ${'network error'} | ${'Something went wrong while updating the task. Please try again.'} | ${new Error()}                         | ${'mockRejectedValue'}
    `(
      'emits an error when there is a $errorType',
      async ({ mockValue, expectedErrorMessage, resolveFunction }) => {
        createComponent({
          mutationHandler: jest.fn()[resolveFunction](mockValue),
          canUpdate: true,
        });

        showDropdown();
        findDropdown().vm.$emit('select', noMilestoneId);
        hideDropdown();

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[expectedErrorMessage]]);
      },
    );
  });

  describe('Tracking event', () => {
    it('tracks updating the milestone', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent({ canUpdate: true });

      showDropdown();
      findDropdown().vm.$emit('select', noMilestoneId);
      hideDropdown();

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_milestone', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_milestone',
        property: 'type_Task',
      });
    });
  });
});
