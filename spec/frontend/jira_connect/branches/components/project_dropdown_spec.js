import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectDropdown from '~/jira_connect/branches/components/project_dropdown.vue';
import { PROJECTS_PER_PAGE } from '~/jira_connect/branches/constants';
import getProjectsQuery from '~/jira_connect/branches/graphql/queries/get_projects.query.graphql';

const localVue = createLocalVue();

const mockProjects = [
  {
    id: 'test',
    name: 'test',
    nameWithNamespace: 'test',
    avatarUrl: 'https://gitlab.com',
    path: 'test-path',
    fullPath: 'test-path',
    repository: {
      empty: false,
    },
  },
  {
    id: 'gitlab',
    name: 'GitLab',
    nameWithNamespace: 'gitlab-org/gitlab',
    avatarUrl: 'https://gitlab.com',
    path: 'gitlab',
    fullPath: 'gitlab-org/gitlab',
    repository: {
      empty: false,
    },
  },
];

const mockProjectsQueryResponse = {
  data: {
    projects: {
      nodes: mockProjects,
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: '',
        endCursor: '',
      },
    },
  },
};
const mockGetProjectsQuerySuccess = jest.fn().mockResolvedValue(mockProjectsQueryResponse);
const mockGetProjectsQueryFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));
const mockQueryLoading = jest.fn().mockReturnValue(new Promise(() => {}));

describe('ProjectDropdown', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdownItemByText = (text) =>
    findAllDropdownItems().wrappers.find((item) => item.text() === text);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  function createMockApolloProvider({ mockGetProjectsQuery = mockGetProjectsQuerySuccess } = {}) {
    localVue.use(VueApollo);

    const mockApollo = createMockApollo([[getProjectsQuery, mockGetProjectsQuery]]);

    return mockApollo;
  }

  function createComponent({ mockApollo, props, mountFn = shallowMount } = {}) {
    wrapper = mountFn(ProjectDropdown, {
      localVue,
      apolloProvider: mockApollo || createMockApolloProvider(),
      propsData: props,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading projects', () => {
    beforeEach(() => {
      createComponent({
        mockApollo: createMockApolloProvider({ mockGetProjectsQuery: mockQueryLoading }),
      });
    });

    it('sets dropdown `loading` prop to `true`', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });

    it('renders loading icon in dropdown', () => {
      expect(findLoadingIcon().isVisible()).toBe(true);
    });
  });

  describe('when projects query succeeds', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      await wrapper.vm.$nextTick();
    });

    it('sets dropdown `loading` prop to `false`', () => {
      expect(findDropdown().props('loading')).toBe(false);
    });

    it('renders dropdown items', () => {
      const dropdownItems = findAllDropdownItems();
      expect(dropdownItems.wrappers).toHaveLength(mockProjects.length);
      expect(dropdownItems.wrappers.map((item) => item.text())).toEqual(
        mockProjects.map((project) => project.nameWithNamespace),
      );
    });

    describe('when selecting a dropdown item', () => {
      it('emits `change` event with the selected project name', async () => {
        const mockProject = mockProjects[0];
        const itemToSelect = findDropdownItemByText(mockProject.nameWithNamespace);
        await itemToSelect.vm.$emit('click');

        expect(wrapper.emitted('change')[0]).toEqual([mockProject]);
      });
    });

    describe('when `selectedProject` prop is specified', () => {
      const mockProject = mockProjects[0];

      beforeEach(async () => {
        wrapper.setProps({
          selectedProject: mockProject,
        });
      });

      it('sets `isChecked` prop of the corresponding dropdown item to `true`', () => {
        expect(findDropdownItemByText(mockProject.nameWithNamespace).props('isChecked')).toBe(true);
      });

      it('sets dropdown text to `selectedBranchName` value', () => {
        expect(findDropdown().props('text')).toBe(mockProject.nameWithNamespace);
      });
    });
  });

  describe('when projects query fails', () => {
    beforeEach(async () => {
      createComponent({
        mockApollo: createMockApolloProvider({ mockGetProjectsQuery: mockGetProjectsQueryFailed }),
      });
      await waitForPromises();
    });

    it('emits `error` event', () => {
      expect(wrapper.emitted('error')).toBeTruthy();
    });
  });

  describe('when searching branches', () => {
    it('triggers a refetch', async () => {
      createComponent({ mountFn: mount });
      await waitForPromises();
      jest.clearAllMocks();

      const mockSearchTerm = 'gitl';
      await findSearchBox().vm.$emit('input', mockSearchTerm);

      expect(mockGetProjectsQuerySuccess).toHaveBeenCalledWith({
        after: '',
        first: PROJECTS_PER_PAGE,
        membership: true,
        search: mockSearchTerm,
        searchNamespaces: true,
        sort: 'similarity',
      });
    });
  });
});
