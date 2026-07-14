import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlCollapsibleListbox, GlFormSelect, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import MoveWorkItemModal from '~/work_items/components/move_work_item_modal.vue';
import moveIssueMutation from '~/sidebar/queries/move_issue.mutation.graphql';
import searchUserProjectsToMove from '~/work_items/graphql/search_user_projects_to_move.query.graphql';
import workItemMoveTargetsQuery from '~/work_items/graphql/work_item_move_targets.query.graphql';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import {
  workItemHierarchyTreeResponse,
  mockHierarchyWidget,
} from 'ee_else_ce_jest/work_items/mock_data';
import { stubComponent } from 'helpers/stub_component';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

const mockProject1 = {
  id: 'gid://gitlab/Project/1',
  name: 'Project 1',
  nameWithNamespace: 'Group / Project 1',
  fullPath: 'group/project-1',
};

const mockProject2 = {
  id: 'gid://gitlab/Project/2',
  name: 'Project 2',
  nameWithNamespace: 'Group / Project 2',
  fullPath: 'group/project-2',
};

const mockProject3 = {
  id: 'gid://gitlab/Project/3',
  name: 'Project 2',
  nameWithNamespace: 'Group / Project 3',
  fullPath: 'group/project-3',
};

const mockProjectsResponse = {
  data: {
    projects: {
      nodes: [mockProject1, mockProject2, mockProject3],
    },
  },
};

const workItemHierarchyResponse = ({ hasChildren = false } = {}) => ({
  data: {
    workItem: {
      ...workItemHierarchyTreeResponse.data.workItem,
      widgets: [
        {
          ...mockHierarchyWidget,
          hasChildren,
        },
      ],
    },
  },
});

const searchProjectsSuccessHandler = jest.fn().mockResolvedValue(mockProjectsResponse);
const workItemHierarchyTreeResponseHandler = jest.fn().mockResolvedValue(workItemHierarchyResponse);
const moveIssueSuccessHandler = jest.fn().mockResolvedValue({
  data: {
    issueMove: {
      issue: {
        id: 'gid://gitlab/Issue/1',
        webUrl: 'http://test.host/group/project-1/-/issues/1',
      },
      errors: [],
    },
  },
});

const ISSUE_GID = 'gid://gitlab/WorkItems::Type/1';
const TASK_GID = 'gid://gitlab/WorkItems::Type/5';

const makeType = (id, name) => ({
  id,
  name,
  iconName: 'issue-type-issue',
  __typename: 'WorkItemType',
});

// Builds a workItemMoveTargets response for a given target namespace. The
// backend returns one WorkItemMoveTarget per source type id; the modal only
// passes one id, so a single entry is enough.
const makeMoveTargetsResponse = ({
  targetFullPath,
  sourceType = makeType(ISSUE_GID, 'Issue'),
  suggestedTargetType = makeType(ISSUE_GID, 'Issue'),
  validTargetTypes = [makeType(ISSUE_GID, 'Issue'), makeType(TASK_GID, 'Task')],
}) => ({
  data: {
    namespace: {
      id: `gid://gitlab/Namespace/${targetFullPath}`,
      workItemMoveTargets: [
        {
          sourceType,
          suggestedTargetType,
          validTargetTypes,
          __typename: 'WorkItemMoveTarget',
        },
      ],
      __typename: 'Namespace',
    },
  },
});

const buildMoveTargetsHandler = (responsesByTargetPath) =>
  jest.fn(({ targetFullPath }) =>
    Promise.resolve(
      responsesByTargetPath[targetFullPath] ??
        makeMoveTargetsResponse({
          targetFullPath,
          suggestedTargetType: null,
          validTargetTypes: [],
        }),
    ),
  );

describe('MoveWorkItemModal', () => {
  let wrapper;
  const hideMock = jest.fn();

  const findModal = () => wrapper.findComponent(GlModal);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectedNamespace = () => wrapper.find('[data-testid="selected-project-namespace"]');
  const findChildItemsWarning = () => wrapper.find('[data-testid="child-items-warning"]');
  const findTypeSelect = () => wrapper.findComponent(GlFormSelect);
  const findNoValidTypesAlert = () => wrapper.find('[data-testid="no-valid-target-types-alert"]');
  const findErrorMessage = () => wrapper.findComponent(GlAlert);

  const defaultMoveTargetsByPath = {
    'group/project-1': makeMoveTargetsResponse({ targetFullPath: 'group/project-1' }),
    'group/project-2': makeMoveTargetsResponse({ targetFullPath: 'group/project-2' }),
    'group/project-3': makeMoveTargetsResponse({ targetFullPath: 'group/project-3' }),
  };

  const createComponent = ({
    props = {},
    searchProjectsHandler = searchProjectsSuccessHandler,
    workItemHierarchyTreeHandler = workItemHierarchyTreeResponseHandler,
    moveIssueHandler = moveIssueSuccessHandler,
    moveTargetsHandler = buildMoveTargetsHandler(defaultMoveTargetsByPath),
  } = {}) => {
    wrapper = shallowMount(MoveWorkItemModal, {
      apolloProvider: createMockApollo([
        [searchUserProjectsToMove, searchProjectsHandler],
        [getWorkItemTreeQuery, workItemHierarchyTreeHandler],
        [workItemMoveTargetsQuery, moveTargetsHandler],
        [moveIssueMutation, moveIssueHandler],
      ]),
      propsData: {
        visible: true,
        fullPath: 'group/project',
        workItemId: 'gid://gitlab/WorkItem/2',
        workItemIid: 'gid://gitlab/WorkItem/1',
        projectId: 'gid://gitlab/Project/2',
        workItemTypeId: ISSUE_GID,
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: hideMock,
          },
        }),
      },
    });
  };

  // Initialize projects data
  const triggerDropdown = async () => {
    findDropdown().vm.$emit('shown');
    await waitForPromises();
  };

  const selectProject = async (projectId) => {
    findDropdown().vm.$emit('select', projectId);
    await waitForPromises();
  };

  // Creates the component with the given move-targets responses, opens the
  // dropdown, and selects a destination project. Returns the move-targets
  // handler so tests can assert on its calls.
  const setupWithMoveTargets = async (responsesByTargetPath, projectId = mockProject1.id) => {
    const moveTargetsHandler = buildMoveTargetsHandler(responsesByTargetPath);
    createComponent({ moveTargetsHandler });
    await triggerDropdown();
    await selectProject(projectId);
    return moveTargetsHandler;
  };

  beforeEach(async () => {
    createComponent();

    await triggerDropdown();
  });

  describe('initial rendering', () => {
    it('renders modal when visible prop is true', () => {
      expect(findModal().props('visible')).toBe(true);
    });

    it('does not render modal when visible prop is false', () => {
      createComponent({ props: { visible: false } });

      expect(findModal().props('visible')).toBe(false);
    });
  });

  describe('toggle text', () => {
    it('renders "Select project" when there is no selected project', () => {
      expect(findDropdown().props('toggleText')).toBe('Select project');
    });

    it('renders project namespace and name when there is a selected project', async () => {
      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

      expect(findDropdown().props('toggleText')).toBe('Group / Project 1');
    });
  });

  describe('project search', () => {
    it('fetches projects when dropdown is shown', () => {
      expect(searchProjectsSuccessHandler).toHaveBeenCalledWith({ search: '', sort: 'stars_desc' });
    });

    it('updates projects list when search is performed', async () => {
      findDropdown().vm.$emit('search', 'test');
      await nextTick();

      expect(searchProjectsSuccessHandler).toHaveBeenCalledWith({
        search: 'test',
        sort: 'similarity',
      });
    });

    it('filters out current project from results', () => {
      const expectedListboxItems = [
        {
          value: 'gid://gitlab/Project/1',
          text: 'Group / Project 1',
          fullPath: 'group/project-1',
        },
        {
          value: 'gid://gitlab/Project/3',
          text: 'Group / Project 3',
          fullPath: 'group/project-3',
        },
      ];

      expect(findDropdown().props('items')).toStrictEqual(expectedListboxItems);
    });
  });

  describe('project selection', () => {
    it('displays selected project namespace when project is selected', async () => {
      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

      expect(findSelectedNamespace().text()).toBe(mockProject1.fullPath);
    });

    it('shows child items warning when project is selected if issue has children', async () => {
      createComponent({
        workItemHierarchyTreeHandler: jest
          .fn()
          .mockResolvedValue(workItemHierarchyResponse({ hasChildren: true })),
      });

      await triggerDropdown();

      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

      expect(findChildItemsWarning().text()).toBe(
        'All child items will also be moved to the selected location.',
      );
    });

    it('does not show child items warning when project is selected if issue does not have children', async () => {
      createComponent({
        workItemHierarchyTreeHandler: jest
          .fn()
          .mockResolvedValue(workItemHierarchyResponse({ hasChildren: false })),
      });

      await triggerDropdown();

      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

      expect(findChildItemsWarning().exists()).toBe(false);
    });
  });

  describe('move operation', () => {
    it('calls move mutation with correct parameters when move is clicked', async () => {
      await selectProject(mockProject1.id);

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(moveIssueSuccessHandler).toHaveBeenCalledWith({
        moveIssueInput: {
          projectPath: 'group/project',
          iid: 'gid://gitlab/WorkItem/1',
          targetProjectPath: mockProject1.fullPath,
          targetWorkItemTypeId: ISSUE_GID,
        },
      });
    });

    it('passes the user-selected target type id to the move mutation', async () => {
      // Backend suggests Issue; user overrides to Task before submitting.
      await selectProject(mockProject1.id);
      findTypeSelect().vm.$emit('input', TASK_GID);
      await nextTick();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(moveIssueSuccessHandler).toHaveBeenCalledWith({
        moveIssueInput: {
          projectPath: 'group/project',
          iid: 'gid://gitlab/WorkItem/1',
          targetProjectPath: mockProject1.fullPath,
          targetWorkItemTypeId: TASK_GID,
        },
      });
    });

    it('redirects to new issue URL on successful move', async () => {
      await selectProject(mockProject1.id);

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(moveIssueSuccessHandler).toHaveBeenCalledWith({
        moveIssueInput: {
          projectPath: 'group/project',
          iid: 'gid://gitlab/WorkItem/1',
          targetProjectPath: mockProject1.fullPath,
          targetWorkItemTypeId: ISSUE_GID,
        },
      });

      expect(visitUrl).toHaveBeenCalledWith('http://test.host/group/project-1/-/issues/1');
      expect(findModal().props('visible')).toBe(false);
    });

    it('shows error alert inside modal when move fails', async () => {
      const moveIssueHandler = jest.fn().mockRejectedValue(new Error('Move failed'));

      createComponent({ moveIssueHandler });

      await triggerDropdown();

      await selectProject(mockProject1.id);

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(findModal().props('visible')).toBe(true);
      expect(findErrorMessage().text()).toBe(
        'Could not be moved. Select another project or try again.',
      );
    });

    it('disables move button when no project is selected', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });
  });

  describe('target work item type selection', () => {
    it('hides the type selector before a destination project is picked', () => {
      expect(findTypeSelect().exists()).toBe(false);
    });

    it('renders the type selector once a destination project is picked', async () => {
      await selectProject(mockProject1.id);

      expect(findTypeSelect().exists()).toBe(true);
    });

    it('queries workItemMoveTargets with the source path, target path, and source type id', async () => {
      const moveTargetsHandler = await setupWithMoveTargets(defaultMoveTargetsByPath);

      expect(moveTargetsHandler).toHaveBeenCalledWith({
        targetFullPath: mockProject1.fullPath,
        sourceFullPath: 'group/project',
        sourceTypeIds: [ISSUE_GID],
      });
    });

    it('lists the validTargetTypes returned by the backend as options', async () => {
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: makeType(ISSUE_GID, 'Issue'),
          validTargetTypes: [makeType(ISSUE_GID, 'Issue')],
        }),
      });

      // Options serialize through the GlFormSelect stub as comma-joined toString;
      // count entries to assert size, then assert the pre-selected value below.
      const optionsAttr = findTypeSelect().attributes('options');
      expect(optionsAttr.split(',')).toHaveLength(1);
      expect(findTypeSelect().attributes('value')).toBe(ISSUE_GID);
    });

    it('pre-selects suggestedTargetType returned by the backend', async () => {
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: makeType(TASK_GID, 'Task'),
          validTargetTypes: [makeType(ISSUE_GID, 'Issue'), makeType(TASK_GID, 'Task')],
        }),
      });

      expect(findTypeSelect().attributes('value')).toBe(TASK_GID);
    });

    it('does not pre-select anything when suggestedTargetType is null', async () => {
      // Backend returns null for suggestedTargetType when no clear match exists;
      // the user must pick manually.
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: null,
          validTargetTypes: [makeType(TASK_GID, 'Task')],
        }),
      });

      expect(findTypeSelect().attributes('value')).toBeUndefined();
      // Move stays enabled; the type selection is validated on submit instead.
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });

    it('shows a validation error and does not move when submitted without a selected type', async () => {
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: null,
          validTargetTypes: [makeType(TASK_GID, 'Task')],
        }),
      });

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(findErrorMessage().text()).toBe('Select a type before moving this item.');
      expect(moveIssueSuccessHandler).not.toHaveBeenCalled();
      expect(findModal().props('visible')).toBe(true);
    });

    it('clears the validation error once a type is selected', async () => {
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: null,
          validTargetTypes: [makeType(TASK_GID, 'Task')],
        }),
      });

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      expect(findErrorMessage().exists()).toBe(true);

      findTypeSelect().vm.$emit('input', TASK_GID);
      await nextTick();

      expect(findErrorMessage().exists()).toBe(false);
    });

    it('shows a warning but keeps move enabled when there are no valid target types', async () => {
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: null,
          validTargetTypes: [],
        }),
      });

      // The button stays enabled regardless of target types; the type
      // selection is validated on submit instead of disabling the button.
      expect(findNoValidTypesAlert().exists()).toBe(true);
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });

    it('resets the type selection when a different project is picked', async () => {
      // First destination: backend suggests Issue. Second destination: backend
      // suggests nothing. Selection should clear when the project changes.
      await setupWithMoveTargets({
        'group/project-1': makeMoveTargetsResponse({
          targetFullPath: 'group/project-1',
          suggestedTargetType: makeType(ISSUE_GID, 'Issue'),
          validTargetTypes: [makeType(ISSUE_GID, 'Issue'), makeType(TASK_GID, 'Task')],
        }),
        'group/project-3': makeMoveTargetsResponse({
          targetFullPath: 'group/project-3',
          suggestedTargetType: null,
          validTargetTypes: [makeType(TASK_GID, 'Task')],
        }),
      });
      expect(findTypeSelect().attributes('value')).toBe(ISSUE_GID);

      await selectProject(mockProject3.id);
      expect(findTypeSelect().attributes('value')).toBeUndefined();
    });

    it('does not render the type selector when workItemTypeId prop is missing', async () => {
      createComponent({ props: { workItemTypeId: '' } });
      await triggerDropdown();
      await selectProject(mockProject1.id);

      expect(findTypeSelect().exists()).toBe(false);
      // Move button stays enabled (no type-selection gate when no type info is available).
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);

      // With no type info, the mutation omits targetWorkItemTypeId entirely
      // (rather than sending null) so the backend preserves the source type.
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(moveIssueSuccessHandler).toHaveBeenCalledWith({
        moveIssueInput: {
          projectPath: 'group/project',
          iid: 'gid://gitlab/WorkItem/1',
          targetProjectPath: mockProject1.fullPath,
        },
      });
    });
  });
});
