import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlCollapsibleListbox, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import MoveWorkItemModal from '~/work_items/components/move_work_item_modal.vue';
import moveIssueMutation from '~/sidebar/queries/move_issue.mutation.graphql';
import searchUserProjectsToMove from '~/work_items/graphql/search_user_projects_to_move.query.graphql';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import { workItemHierarchyTreeResponse, mockHierarchyWidget } from 'jest/work_items/mock_data';
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

describe('MoveWorkItemModal', () => {
  let wrapper;
  const hideMock = jest.fn();

  const findModal = () => wrapper.findComponent(GlModal);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectedNamespace = () => wrapper.find('[data-testid="selected-project-namespace"]');
  const findChildItemsWarning = () => wrapper.find('[data-testid="child-items-warning"]');
  const findErrorMessage = () => wrapper.findComponent(GlAlert);

  const createComponent = ({
    props = {},
    searchProjectsHandler = searchProjectsSuccessHandler,
    workItemHierarchyTreeHandler = workItemHierarchyTreeResponseHandler,
    moveIssueHandler = moveIssueSuccessHandler,
  } = {}) => {
    wrapper = shallowMount(MoveWorkItemModal, {
      apolloProvider: createMockApollo([
        [searchUserProjectsToMove, searchProjectsHandler],
        [getWorkItemTreeQuery, workItemHierarchyTreeHandler],
        [moveIssueMutation, moveIssueHandler],
      ]),
      propsData: {
        visible: true,
        fullPath: 'group/project',
        workItemId: 'gid://gitlab/WorkItem/2',
        workItemIid: 'gid://gitlab/WorkItem/1',
        projectId: 'gid://gitlab/Project/2',
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

      expect(findSelectedNamespace().text()).toBe(mockProject1.nameWithNamespace);
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
      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

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

    it('redirects to new issue URL on successful move', async () => {
      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(moveIssueSuccessHandler).toHaveBeenCalledWith({
        moveIssueInput: {
          projectPath: 'group/project',
          iid: 'gid://gitlab/WorkItem/1',
          targetProjectPath: mockProject1.fullPath,
        },
      });

      expect(visitUrl).toHaveBeenCalledWith('http://test.host/group/project-1/-/issues/1');
      expect(findModal().props('visible')).toBe(false);
    });

    it('shows error alert inside modal when move fails', async () => {
      const moveIssueHandler = jest.fn().mockRejectedValue(new Error('Move failed'));

      createComponent({ moveIssueHandler });

      await triggerDropdown();

      findDropdown().vm.$emit('select', mockProject1.id);
      await nextTick();

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
});
