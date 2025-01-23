import Vue from 'vue';
import {
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlDisclosureDropdown,
} from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDevelopmentQuery from '~/work_items/graphql/work_item_development.query.graphql';
import workItemDevelopmentUpdatedSubscription from '~/work_items/graphql/work_item_development.subscription.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { STATE_CLOSED, STATE_OPEN } from '~/work_items/constants';

import {
  workItemByIidResponseFactory,
  workItemDevelopmentFragmentResponse,
  workItemDevelopmentMRNodes,
  workItemDevelopmentResponse,
} from 'jest/work_items/mock_data';

import WorkItemDevelopment from '~/work_items/components/work_item_development/work_item_development.vue';
import WorkItemDevelopmentRelationshipList from '~/work_items/components/work_item_development/work_item_development_relationship_list.vue';
import WorkItemCreateBranchMergeRequestModal from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_modal.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';

describe('WorkItemDevelopment CE', () => {
  Vue.use(VueApollo);

  let wrapper;
  let mockApollo;

  const workItemSucessQueryHandler = ({ state = STATE_OPEN } = {}) => {
    return jest.fn().mockResolvedValue(workItemByIidResponseFactory({ canUpdate: true, state }));
  };

  const devWidgetWithOneMR = workItemDevelopmentResponse({
    developmentItems: workItemDevelopmentFragmentResponse({
      mrNodes: [workItemDevelopmentMRNodes[0]],
      willAutoCloseByMergeRequest: true,
      featureFlagNodes: null,
      branchNodes: [],
      relatedMergeRequests: [],
    }),
  });

  const devWidgetWithMoreThanOneMR = workItemDevelopmentResponse({
    developmentItems: workItemDevelopmentFragmentResponse({
      mrNodes: workItemDevelopmentMRNodes,
      willAutoCloseByMergeRequest: true,
      featureFlagNodes: null,
      branchNodes: [],
      relatedMergeRequests: [],
    }),
  });

  const devWidgetWithAutoCloseDisabled = workItemDevelopmentResponse({
    developmentItems: workItemDevelopmentFragmentResponse({
      mrNodes: workItemDevelopmentMRNodes,
      willAutoCloseByMergeRequest: false,
      featureFlagNodes: null,
      branchNodes: [],
      relatedMergeRequests: [],
    }),
  });

  const devWidgetSuccessHandlerWithAutoCloseDisabled = jest
    .fn()
    .mockResolvedValue(devWidgetWithAutoCloseDisabled);
  const devWidgetSuccessQueryHandlerWithOneMR = jest.fn().mockResolvedValue(devWidgetWithOneMR);
  const devWidgeSuccessQueryHandlerWithMRList = jest
    .fn()
    .mockResolvedValue(devWidgetWithMoreThanOneMR);
  const workItemDevelopmentUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const createComponent = ({
    mountFn = shallowMountExtended,
    workItemId = 'gid://gitlab/WorkItem/1',
    workItemIid = '1',
    workItemFullPath = 'full-path',
    workItemType = 'Issue',
    workItemQueryHandler = workItemSucessQueryHandler(),
    workItemDevelopmentQueryHandler = devWidgetSuccessQueryHandlerWithOneMR,
  } = {}) => {
    mockApollo = createMockApollo([
      [workItemByIidQuery, workItemQueryHandler],
      [workItemDevelopmentQuery, workItemDevelopmentQueryHandler],
      [workItemDevelopmentUpdatedSubscription, workItemDevelopmentUpdatedSubscriptionHandler],
    ]);

    wrapper = mountFn(WorkItemDevelopment, {
      apolloProvider: mockApollo,
      directives: {
        GlModal: createMockDirective('gl-modal'),
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        workItemId,
        workItemIid,
        workItemFullPath,
        workItemType,
      },
      stubs: {
        WorkItemCreateBranchMergeRequestModal: true,
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
        GlDisclosureDropdownGroup,
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findAddButton = () => wrapper.findComponent(WorkItemActionsSplitButton);
  const findMoreInformation = () => wrapper.findByTestId('more-information');
  const findRelationshipList = () => wrapper.findComponent(WorkItemDevelopmentRelationshipList);
  const findCreateOptionsDropdown = () => wrapper.findByTestId('create-options-dropdown');
  const findCreateBranchMergeRequestModal = () =>
    wrapper.findComponent(WorkItemCreateBranchMergeRequestModal);
  const findDropdownGroups = () =>
    findCreateOptionsDropdown().findAllComponents(GlDisclosureDropdownGroup);
  const findWorkItemCreateMergeRequestModal = () =>
    wrapper.findComponent(WorkItemCreateBranchMergeRequestModal);

  describe('Default', () => {
    it('should show the widget label', async () => {
      createComponent();
      await waitForPromises();

      expect(findCrudComponent().props('title')).toBe('Development');
    });

    it('should render the add button when `canUpdate` is true', async () => {
      createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(findAddButton().exists()).toBe(true);
    });

    it('does not render the modal when the queries are still loading', () => {
      createComponent({ mountFn: mountExtended });

      expect(findWorkItemCreateMergeRequestModal().exists()).toBe(false);
    });

    it('renders the modal when the queries are have loaded', async () => {
      createComponent({ mountFn: mountExtended });
      await waitForPromises();

      expect(findWorkItemCreateMergeRequestModal().exists()).toBe(true);
    });
  });

  describe('when the response is successful', () => {
    describe('when there is a list of MR`s', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('should show the relationship list', () => {
        expect(findRelationshipList().exists()).toBe(true);
      });
    });

    it('when auto close flag is disabled, should not show the "i" indicator', async () => {
      createComponent({
        workItemDevelopmentQueryHandler: devWidgetSuccessHandlerWithAutoCloseDisabled,
      });
      await waitForPromises();

      expect(findMoreInformation().exists()).toBe(false);
    });

    it('when auto close flag is enabled, should show the "i" indicator', async () => {
      createComponent({
        workItemDevelopmentQueryHandler: devWidgetSuccessQueryHandlerWithOneMR,
      });

      await waitForPromises();

      expect(findMoreInformation().exists()).toBe(true);
    });

    it.each`
      developmentWidgetQueryHandler            | message                                                            | workItemState   | linkedMRsNumber
      ${devWidgetSuccessQueryHandlerWithOneMR} | ${'This task will be closed when the following is merged.'}        | ${STATE_OPEN}   | ${1}
      ${devWidgeSuccessQueryHandlerWithMRList} | ${'This task will be closed when any of the following is merged.'} | ${STATE_OPEN}   | ${workItemDevelopmentMRNodes.length}
      ${devWidgeSuccessQueryHandlerWithMRList} | ${'The task was closed automatically when a branch was merged.'}   | ${STATE_CLOSED} | ${workItemDevelopmentMRNodes.length}
    `(
      'when the workItemState is `$workItemState` and number of linked MRs is `$linkedMRsNumber` shows message `$message`',
      async ({ developmentWidgetQueryHandler, message, workItemState }) => {
        createComponent({
          workItemQueryHandler: workItemSucessQueryHandler({ state: workItemState }),
          workItemDevelopmentQueryHandler: developmentWidgetQueryHandler,
        });

        await waitForPromises();

        expect(findMoreInformation().attributes('aria-label')).toBe(message);
      },
    );
  });

  describe('Create branch/merge request flow', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
      return waitForPromises();
    });

    it('should not show the create branch or merge request flow by default', () => {
      expect(findCreateBranchMergeRequestModal().props('showModal')).toBe(false);
    });

    describe('Add button', () => {
      it('should show the options in dropdown on click', () => {
        const groups = findDropdownGroups();
        const mergeRequestGroup = groups.at(0);
        const branchGroup = groups.at(1);

        expect(groups).toHaveLength(2);

        expect(mergeRequestGroup.props('group').name).toBe('Merge request');
        expect(mergeRequestGroup.props('group').items).toEqual([
          expect.objectContaining({ text: 'Create merge request' }),
        ]);

        expect(branchGroup.props('group').name).toBe('Branch');
        expect(branchGroup.props('group').items).toEqual([
          expect.objectContaining({ text: 'Create branch' }),
        ]);
      });
    });
  });
});
