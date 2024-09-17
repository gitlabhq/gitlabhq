import { GlDisclosureDropdown, GlLabel } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import {
  TRACKING_CATEGORY_SHOW,
  I18N_WORK_ITEM_ERROR_FETCHING_LABELS,
} from '~/work_items/constants';
import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue';
import groupLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import projectLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import {
  projectLabelsResponse,
  groupLabelsResponse,
  getProjectLabelsResponse,
  mockLabels,
  workItemByIidResponseFactory,
  updateWorkItemMutationResponseFactory,
  updateWorkItemMutationErrorResponse,
} from '../mock_data';

Vue.use(VueApollo);

const workItemId = 'gid://gitlab/WorkItem/1';

describe('WorkItemLabels component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const label1Id = mockLabels[0].id;
  const label2Id = mockLabels[1].id;
  const label3Id = mockLabels[2].id;

  const workItemQuerySuccess = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ labels: null }));
  const workItemQueryWithLabelsHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ labels: mockLabels }));
  const workItemQueryWithFewLabelsHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ labels: [mockLabels[0], mockLabels[1]] }));
  const projectLabelsQueryHandler = jest.fn().mockResolvedValue(projectLabelsResponse);
  const groupLabelsQueryHandler = jest.fn().mockResolvedValue(groupLabelsResponse);
  const errorHandler = jest.fn().mockRejectedValue('Error');
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ labels: [mockLabels[0]] }));
  const successRemoveLabelWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ labels: [mockLabels[0]] }));
  const successRemoveAllLabelWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ labels: [] }));
  const successAddRemoveLabelWorkItemMutationHandler = jest.fn().mockResolvedValue(
    updateWorkItemMutationResponseFactory({
      labels: [mockLabels[0], mockLabels[2]],
    }),
  );

  const createComponent = ({
    canUpdate = true,
    isGroup = false,
    workItemQueryHandler = workItemQuerySuccess,
    searchQueryHandler = projectLabelsQueryHandler,
    updateWorkItemMutationHandler = successUpdateWorkItemMutationHandler,
    workItemIid = '1',
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLabels, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [projectLabelsQuery, searchQueryHandler],
        [groupLabelsQuery, groupLabelsQueryHandler],
        [updateWorkItemMutation, updateWorkItemMutationHandler],
      ]),
      provide: {
        canAdminLabel: true,
        issuesListPath: 'test-project-path/issues',
        labelsManagePath: 'test-project-path/labels',
      },
      propsData: {
        workItemId,
        workItemIid,
        canUpdate,
        isGroup,
        fullPath: 'test-project-path',
        workItemType: 'Task',
      },
    });
  };

  const findWorkItemSidebarDropdownWidget = () =>
    wrapper.findComponent(WorkItemSidebarDropdownWidget);
  const findAllLabels = () => wrapper.findAllComponents(GlLabel);
  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findRegularLabel = () => findAllLabels().at(0);
  const findLabelWithDescription = () => findAllLabels().at(2);
  const findDropdownContentsCreateView = () => wrapper.findComponent(DropdownContentsCreateView);
  const findCreateLabelButton = () => wrapper.findByTestId('create-label');
  const findManageLabelsButton = () => wrapper.findByTestId('manage-labels');

  const showDropdown = () => {
    findWorkItemSidebarDropdownWidget().vm.$emit('dropdownShown');
  };

  const updateLabels = (labels) => {
    findWorkItemSidebarDropdownWidget().vm.$emit('updateSelected', labels);
    findWorkItemSidebarDropdownWidget().vm.$emit('updateValue', labels);
  };

  const getMutationInput = (addLabelIds, removeLabelIds) => {
    return {
      input: {
        id: workItemId,
        labelsWidget: {
          addLabelIds,
          removeLabelIds,
        },
      },
    };
  };

  const expectDropdownCountToBe = (count, toggleDropdownText) => {
    expect(findWorkItemSidebarDropdownWidget().props('itemValue')).toHaveLength(count);
    expect(findWorkItemSidebarDropdownWidget().props('toggleDropdownText')).toBe(
      toggleDropdownText,
    );
  };

  it('renders the work item sidebar dropdown widget with default props', () => {
    createComponent();

    expect(findWorkItemSidebarDropdownWidget().props()).toMatchObject({
      dropdownLabel: 'Labels',
      canUpdate: true,
      dropdownName: 'label',
      updateInProgress: false,
      toggleDropdownText: 'No labels',
      headerText: 'Select labels',
      resetButtonLabel: 'Clear',
      multiSelect: true,
      showFooter: true,
      itemValue: [],
    });
    expect(findAllLabels()).toHaveLength(0);
  });

  it('renders the labels when they are already present', async () => {
    createComponent({
      workItemQueryHandler: workItemQueryWithLabelsHandler,
    });

    await waitForPromises();

    expect(workItemQueryWithLabelsHandler).toHaveBeenCalled();

    expect(findWorkItemSidebarDropdownWidget().props('itemValue')).toStrictEqual([
      label1Id,
      label2Id,
      label3Id,
    ]);
    expect(findAllLabels()).toHaveLength(3);
    expect(findRegularLabel().props()).toMatchObject({
      backgroundColor: '#f00',
      title: 'Label 1',
      target: 'test-project-path/issues?label_name[]=Label%201',
      scoped: false,
      showCloseButton: true,
    });
    expect(findLabelWithDescription().props('description')).toBe('Label 3 description');
  });

  it('renders the labels without close button when canUpdate is false', async () => {
    createComponent({
      workItemQueryHandler: workItemQueryWithLabelsHandler,
      canUpdate: false,
    });

    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props('canUpdate')).toBe(false);
    expect(findRegularLabel().props('showCloseButton')).toBe(false);
  });

  it.each`
    expectedAssertion                                                  | searchTerm   | handler                                                                   | result
    ${'when dropdown is shown'}                                        | ${''}        | ${projectLabelsQueryHandler}                                              | ${3}
    ${'when correct input is entered'}                                 | ${'Label 1'} | ${jest.fn().mockResolvedValue(getProjectLabelsResponse([mockLabels[0]]))} | ${1}
    ${'and shows no matching results when incorrect input is entered'} | ${'Label 2'} | ${jest.fn().mockResolvedValue(getProjectLabelsResponse([]))}              | ${0}
  `('calls search label query $expectedAssertion', async ({ searchTerm, result, handler }) => {
    createComponent({
      searchQueryHandler: handler,
    });

    showDropdown();
    await findWorkItemSidebarDropdownWidget().vm.$emit('searchStarted', searchTerm);

    expect(findWorkItemSidebarDropdownWidget().props('loading')).toBe(true);

    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props('listItems')).toHaveLength(result);
    expect(handler).toHaveBeenCalledWith({
      fullPath: 'test-project-path',
      searchTerm,
    });
    expect(groupLabelsQueryHandler).not.toHaveBeenCalled();
    expect(findWorkItemSidebarDropdownWidget().props('loading')).toBe(false);
  });

  it('filters search results by title in frontend', async () => {
    createComponent({
      searchQueryHandler: jest.fn().mockResolvedValue(getProjectLabelsResponse(mockLabels)),
    });

    showDropdown();
    await findWorkItemSidebarDropdownWidget().vm.$emit('searchStarted', mockLabels[0].title);

    expect(findWorkItemSidebarDropdownWidget().props('loading')).toBe(true);

    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props('listItems')).toHaveLength(1);
    expect(findWorkItemSidebarDropdownWidget().props('loading')).toBe(false);
  });

  it('emits error event if search query fails', async () => {
    createComponent({ searchQueryHandler: errorHandler });
    showDropdown();
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[I18N_WORK_ITEM_ERROR_FETCHING_LABELS]]);
  });

  it('passes the correct props to clear search text on item select', () => {
    createComponent();

    expect(findWorkItemSidebarDropdownWidget().props('clearSearchOnItemSelect')).toBe(true);
  });

  it('update labels when labels are added', async () => {
    createComponent({
      workItemQueryHandler: workItemQuerySuccess,
      updateWorkItemMutationHandler: successUpdateWorkItemMutationHandler,
    });

    await waitForPromises();

    showDropdown();

    expectDropdownCountToBe(0, 'No labels');

    updateLabels([label1Id]);

    await waitForPromises();

    expectDropdownCountToBe(1, '1 label');
    expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith(
      getMutationInput([label1Id], []),
    );
  });

  it('update labels when labels are removed', async () => {
    createComponent({
      workItemQueryHandler: workItemQueryWithLabelsHandler,
      updateWorkItemMutationHandler: successRemoveLabelWorkItemMutationHandler,
    });

    await waitForPromises();

    showDropdown();

    expectDropdownCountToBe(3, '3 labels');

    updateLabels([label1Id]);

    await waitForPromises();

    expectDropdownCountToBe(1, '1 label');
    expect(successRemoveLabelWorkItemMutationHandler).toHaveBeenCalledWith(
      getMutationInput([], [label2Id, label3Id]),
    );
  });

  it('update labels when labels are added or removed at same time', async () => {
    createComponent({
      workItemQueryHandler: workItemQueryWithFewLabelsHandler,
      updateWorkItemMutationHandler: successAddRemoveLabelWorkItemMutationHandler,
    });

    await waitForPromises();

    showDropdown();

    expectDropdownCountToBe(2, '2 labels');

    updateLabels([label1Id, label3Id]);

    await waitForPromises();

    expectDropdownCountToBe(2, '2 labels');
    expect(successAddRemoveLabelWorkItemMutationHandler).toHaveBeenCalledWith(
      getMutationInput([label3Id], [label2Id]),
    );
  });

  it('clears all labels when updateValue has no labels', async () => {
    createComponent({
      workItemQueryHandler: workItemQueryWithLabelsHandler,
      updateWorkItemMutationHandler: successRemoveAllLabelWorkItemMutationHandler,
    });

    await waitForPromises();

    showDropdown();

    expectDropdownCountToBe(3, '3 labels');

    findWorkItemSidebarDropdownWidget().vm.$emit('updateValue', []);

    await waitForPromises();

    expectDropdownCountToBe(0, 'No labels');
    expect(successRemoveAllLabelWorkItemMutationHandler).toHaveBeenCalledWith(
      getMutationInput([], [label1Id, label2Id, label3Id]),
    );
  });

  it('shows selected labels at top of list', async () => {
    const [label1, label2, label3] = mockLabels;
    const label999 = {
      __typename: 'Label',
      id: 'gid://gitlab/Label/999',
      title: 'Label 999',
      description: 'Label not in the label query result',
      color: '#fff',
      textColor: '#000',
    };

    createComponent({
      workItemQueryHandler: workItemQuerySuccess,
      updateWorkItemMutationHandler: jest.fn().mockResolvedValue(
        updateWorkItemMutationResponseFactory({
          labels: [label1, label999],
        }),
      ),
    });

    updateLabels([label1Id, label999.id]);

    showDropdown();

    await waitForPromises();

    const selected = [
      { color: label1.color, text: label1.title, value: label1.id },
      { color: label999.color, text: label999.title, value: label999.id },
    ];

    const unselected = [
      { color: label2.color, text: label2.title, value: label2.id },
      { color: label3.color, text: label3.title, value: label3.id },
    ];

    expect(findWorkItemSidebarDropdownWidget().props('listItems')).toEqual([
      { options: selected, text: 'Selected' },
      { options: unselected, text: 'All', textSrOnly: true },
    ]);
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      trackingSpy = null;
    });

    it('tracks editing the labels on dropdown widget updateValue', async () => {
      showDropdown();
      updateLabels([label1Id]);

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_labels', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_label',
        property: 'type_Task',
      });
    });
  });

  it.each`
    errorType          | expectedErrorMessage                                                      | failureHandler
    ${'graphql error'} | ${'Something went wrong while updating the work item. Please try again.'} | ${jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse)}
    ${'network error'} | ${'Something went wrong while updating the work item. Please try again.'} | ${jest.fn().mockRejectedValue(new Error())}
  `(
    'emits an error when there is a $errorType',
    async ({ expectedErrorMessage, failureHandler }) => {
      createComponent({
        updateWorkItemMutationHandler: failureHandler,
      });

      updateLabels([label1Id]);

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[expectedErrorMessage]]);
    },
  );

  it('skips calling the work item query when missing workItemIid', async () => {
    createComponent({ workItemIid: '' });

    await waitForPromises();

    expect(workItemQuerySuccess).not.toHaveBeenCalled();
  });

  describe('when group context', () => {
    beforeEach(async () => {
      createComponent({ isGroup: true });

      await waitForPromises();
    });

    it('calls the group labels query on search', async () => {
      showDropdown();
      await waitForPromises();

      expect(groupLabelsQueryHandler).toHaveBeenCalled();
    });
  });

  describe('create/manage label buttons', () => {
    describe('when project context', () => {
      beforeEach(() => {
        createComponent({ isGroup: false });
      });

      it('renders "Create project label" button', () => {
        expect(findCreateLabelButton().text()).toBe('Create project label');
      });

      it('renders "Manage project labels" link', () => {
        expect(findManageLabelsButton().text()).toBe('Manage project labels');
        expect(findManageLabelsButton().attributes('href')).toBe('test-project-path/labels');
      });
    });

    describe('when group context', () => {
      beforeEach(() => {
        createComponent({ isGroup: true });
      });

      it('renders "Create group label" button', () => {
        expect(findCreateLabelButton().text()).toBe('Create group label');
      });

      it('renders "Manage group labels" link', () => {
        expect(findManageLabelsButton().text()).toBe('Manage group labels');
        expect(findManageLabelsButton().attributes('href')).toBe('test-project-path/labels');
      });
    });

    describe('creating project label', () => {
      beforeEach(async () => {
        createComponent();

        findCreateLabelButton().vm.$emit('click');
        await nextTick();
      });

      describe('when "Create project label" button is clicked', () => {
        it('renders "Create label" dropdown', () => {
          expect(findDisclosureDropdown().props()).toMatchObject({
            block: true,
            startOpened: true,
            toggleText: 'No labels',
          });
          expect(findDropdownContentsCreateView().props()).toEqual({
            attrWorkspacePath: 'test-project-path',
            fullPath: 'test-project-path',
            labelCreateType: 'project',
            searchKey: '',
            workspaceType: 'project',
          });
        });
      });

      describe('when "hideCreateView" event is emitted', () => {
        it('hides dropdown', async () => {
          expect(findDisclosureDropdown().exists()).toBe(true);
          expect(findDropdownContentsCreateView().exists()).toBe(true);

          findDropdownContentsCreateView().vm.$emit('hideCreateView');
          await nextTick();

          expect(findDisclosureDropdown().exists()).toBe(false);
          expect(findDropdownContentsCreateView().exists()).toBe(false);
        });
      });

      describe('when "labelCreated" event is emitted', () => {
        it('updates "createdLabelId" value and hides dropdown', async () => {
          expect(findWorkItemSidebarDropdownWidget().props('createdLabelId')).toBe(undefined);
          expect(findDisclosureDropdown().exists()).toBe(true);
          expect(findDropdownContentsCreateView().exists()).toBe(true);

          findDropdownContentsCreateView().vm.$emit('labelCreated', {
            id: 'gid://gitlab/Label/55',
            name: 'New label',
          });
          await nextTick();

          expect(findWorkItemSidebarDropdownWidget().props('createdLabelId')).toBe(
            'gid://gitlab/Label/55',
          );
          expect(findDisclosureDropdown().exists()).toBe(false);
          expect(findDropdownContentsCreateView().exists()).toBe(false);
        });
      });
    });
  });
});
