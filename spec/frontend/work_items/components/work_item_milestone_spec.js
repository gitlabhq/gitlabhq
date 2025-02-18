import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLink } from '@gitlab/ui';
import WorkItemMilestone from '~/work_items/components/work_item_milestone.vue';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
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

describe('WorkItemMilestone component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';

  const findSidebarDropdownWidget = () => wrapper.findComponent(WorkItemSidebarDropdownWidget);

  const successSearchQueryHandler = jest.fn().mockResolvedValue(projectMilestonesResponse);
  const successSearchWithNoMatchingMilestones = jest
    .fn()
    .mockResolvedValue(projectMilestonesResponseWithNoMilestones);
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);

  const showDropdown = () => findSidebarDropdownWidget().vm.$emit('dropdownShown');

  const createComponent = ({
    mountFn = shallowMountExtended,
    canUpdate = true,
    milestone = mockMilestoneWidgetResponse,
    searchQueryHandler = successSearchQueryHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
    isGroup = false,
  } = {}) => {
    wrapper = mountFn(WorkItemMilestone, {
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
        isGroup,
      },
    });
  };

  it('has "Milestone" label', () => {
    createComponent();

    expect(findSidebarDropdownWidget().props('dropdownLabel')).toBe('Milestone');
  });

  describe('Default text with canUpdate false and milestone value', () => {
    describe.each`
      description             | milestone                      | value
      ${'when no milestone'}  | ${null}                        | ${'None'}
      ${'when milestone set'} | ${mockMilestoneWidgetResponse} | ${mockMilestoneWidgetResponse.title}
    `('$description', ({ milestone, value }) => {
      it(`has a value of "${value}"`, () => {
        createComponent({ mountFn: mountExtended, canUpdate: false, milestone });

        expect(findSidebarDropdownWidget().props('canUpdate')).toBe(false);
        expect(wrapper.text()).toContain(value);
      });
    });

    it('shows set milestone with attributes required for popover', () => {
      createComponent({ mountFn: mountExtended, milestone: mockMilestoneWidgetResponse });

      const milestoneLink = wrapper.findComponent(GlLink);
      expect(milestoneLink.classes()).toContain('has-popover');
      expect(milestoneLink.attributes()).toEqual(
        expect.objectContaining({
          'data-placement': 'left',
          'data-reference-type': 'milestone',
          'data-milestone': '30',
        }),
      );
    });
  });

  describe('Dropdown search', () => {
    it('shows no matching results when no items', () => {
      createComponent({
        searchQueryHandler: successSearchWithNoMatchingMilestones,
      });

      expect(findSidebarDropdownWidget().props('listItems')).toHaveLength(0);
    });
  });

  describe('Dropdown options', () => {
    beforeEach(() => {
      createComponent({ canUpdate: true });
    });

    it('calls successSearchQueryHandler with variables when dropdown is opened', async () => {
      showDropdown();

      await waitForPromises();

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

      expect(findSidebarDropdownWidget().props('loading')).toBe(true);
    });

    it('shows the milestones in dropdown when the items have finished fetching', async () => {
      showDropdown();

      await waitForPromises();

      expect(findSidebarDropdownWidget().props('loading')).toBe(false);
      expect(findSidebarDropdownWidget().props('listItems')).toHaveLength(
        projectMilestonesResponse.data.workspace.attributes.nodes.length,
      );
    });

    it('changes the milestone to null when clicked on Clear', async () => {
      findSidebarDropdownWidget().vm.$emit('updateValue', null);

      await nextTick();

      expect(findSidebarDropdownWidget().props('updateInProgress')).toBe(true);

      await waitForPromises();
      expect(findSidebarDropdownWidget().props('updateInProgress')).toBe(false);
      expect(findSidebarDropdownWidget().props('itemValue')).toBe(null);
    });

    it('changes the milestone to the selected milestone', async () => {
      const milestoneAtIndex = projectMilestonesResponse.data.workspace.attributes.nodes[0];

      showDropdown();

      await waitForPromises();
      findSidebarDropdownWidget().vm.$emit('updateValue', milestoneAtIndex.id);

      await nextTick();

      expect(findSidebarDropdownWidget().props('itemValue')).toBe(milestoneAtIndex.id);
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
        findSidebarDropdownWidget().vm.$emit('updateValue', null);

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
      findSidebarDropdownWidget().vm.$emit('updateValue', null);

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_milestone', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_milestone',
        property: 'type_Task',
      });
    });
  });
});
