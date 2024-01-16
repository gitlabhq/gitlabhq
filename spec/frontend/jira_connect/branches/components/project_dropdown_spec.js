import { GlAvatarLabeled, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectDropdown from '~/jira_connect/branches/components/project_dropdown.vue';
import { PROJECTS_PER_PAGE } from '~/jira_connect/branches/constants';
import getProjectsQuery from '~/jira_connect/branches/graphql/queries/get_projects.query.graphql';

import { mockProjects, mockProjects2 } from '../mock_data';

const mockProjectsQueryResponse = {
  data: {
    projects: {
      __typename: 'ProjectsConnection',
      nodes: mockProjects,
      pageInfo: {
        __typename: 'PageInfo',
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

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllGlListboxItems = () => wrapper.findAllComponents(GlListboxItem);

  function createMockApolloProvider({ mockGetProjectsQuery = mockGetProjectsQuerySuccess } = {}) {
    Vue.use(VueApollo);

    const mockApollo = createMockApollo([[getProjectsQuery, mockGetProjectsQuery]]);

    return mockApollo;
  }

  function createComponent({ mockApollo, props, mountFn = shallowMount } = {}) {
    wrapper = mountFn(ProjectDropdown, {
      apolloProvider: mockApollo || createMockApolloProvider(),
      propsData: props,
      stubs: { GlCollapsibleListbox },
    });
  }

  describe('when loading projects', () => {
    beforeEach(() => {
      createComponent({
        mockApollo: createMockApolloProvider({ mockGetProjectsQuery: mockQueryLoading }),
      });
    });

    it('sets dropdown `loading` prop to `true`', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });
  });

  describe('when projects query succeeds', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('sets dropdown `loading` prop to `false`', () => {
      expect(findDropdown().props('loading')).toBe(false);
    });

    it('renders dropdown items with correct props', () => {
      const dropdownItems = findDropdown().props('items');
      expect(dropdownItems).toHaveLength(mockProjects.length);
      expect(dropdownItems).toMatchObject(mockProjects);
    });

    it('renders dropdown items with correct template', () => {
      expect(findAllGlListboxItems()).toHaveLength(mockProjects.length);
      const avatars = findAllGlListboxItems().wrappers.map((item) =>
        item.findComponent(GlAvatarLabeled),
      );
      const avatarAttributes = avatars.map((avatar) => avatar.attributes());
      const avatarProps = avatars.map((avatar) => avatar.props());

      expect(avatarProps).toMatchObject(
        mockProjects.map((project) => ({
          label: project.name,
          subLabel: project.nameWithNamespace,
        })),
      );
      expect(avatarAttributes).toMatchObject(
        mockProjects.map((project) => ({
          src: project.avatarUrl,
          'entity-name': project.name,
        })),
      );
    });

    describe('when selecting a dropdown item', () => {
      it('emits `change` event with the selected project', async () => {
        const mockProject = mockProjects[0];
        await findDropdown().vm.$emit('select', mockProject.id);

        expect(wrapper.emitted('change')[0]).toEqual([mockProject]);
      });
    });

    describe('when `selectedProject` prop is specified', () => {
      const mockProject = mockProjects[0];

      beforeEach(() => {
        createComponent({ props: { selectedProject: mockProject } });
      });

      it('selects the specified item', () => {
        expect(findDropdown().props('selected')).toBe(mockProject.id);
      });
    });
  });

  describe('when projects query succeeds and has pagination', () => {
    const mockProjectsWithPaginationQueryResponse = {
      data: {
        projects: {
          __typename: 'ProjectsConnection',
          nodes: mockProjects2,
          pageInfo: {
            __typename: 'PageInfo',
            hasNextPage: true,
            hasPreviousPage: false,
            startCursor: '',
            endCursor: 'end123',
          },
        },
      },
    };
    const mockGetProjectsQuery = jest.fn();

    beforeEach(async () => {
      mockGetProjectsQuery
        .mockResolvedValueOnce(mockProjectsWithPaginationQueryResponse)
        .mockResolvedValueOnce(mockProjectsQueryResponse);

      createComponent({
        mockApollo: createMockApolloProvider({
          mockGetProjectsQuery,
        }),
      });
      await waitForPromises();
    });

    afterEach(() => {
      mockGetProjectsQuery.mockReset();
    });

    it('uses infinite-scroll', () => {
      expect(findDropdown().props()).toMatchObject({
        infiniteScroll: true,
        infiniteScrollLoading: false,
      });
    });

    describe('when "bottom-reached" event is emitted', () => {
      beforeEach(() => {
        findDropdown().vm.$emit('bottom-reached');
      });

      it('sets infinite-scroll-loading to true', () => {
        expect(findDropdown().props('infiniteScrollLoading')).toBe(true);
      });

      it('calls fetchMore to get next page', () => {
        expect(mockGetProjectsQuery).toHaveBeenCalledTimes(2);
        expect(mockGetProjectsQuery).toHaveBeenCalledWith(
          expect.objectContaining({
            after: 'end123',
          }),
        );
      });

      it('appends query results to "items"', async () => {
        const allProjects = [...mockProjects2, ...mockProjects];

        await waitForPromises();

        expect(findDropdown().props('infiniteScrollLoading')).toBe(false);

        const dropdownItems = findDropdown().props('items');
        expect(dropdownItems).toHaveLength(allProjects.length);
        expect(dropdownItems).toMatchObject(allProjects);
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
      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });

  describe('when searching branches', () => {
    it('triggers a refetch', async () => {
      createComponent({ mountFn: mount });

      const mockSearchTerm = 'gitl';
      await findDropdown().vm.$emit('search', mockSearchTerm);

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
