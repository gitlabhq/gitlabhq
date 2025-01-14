import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import organizationProjectsGraphQlResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import { SORT_DIRECTION_ASC, SORT_ITEM_NAME } from '~/organizations/shared/constants';
import NewProjectButton from '~/organizations/shared/components/new_project_button.vue';
import GroupsAndProjectsEmptyState from '~/organizations/shared/components/groups_and_projects_empty_state.vue';
import projectsQuery from '~/organizations/shared/graphql/queries/projects.query.graphql';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { formatProjects } from '~/organizations/shared/utils';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { createAlert } from '~/alert';
import { DEFAULT_PER_PAGE } from '~/api';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  pageInfoMultiplePages,
  pageInfoEmpty,
  pageInfoOnePage,
} from 'jest/organizations/mock_data';

jest.mock('~/alert');
jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url',
  () => 'empty-projects-md.svg',
);

Vue.use(VueApollo);

const {
  data: {
    organization: {
      projects: { nodes },
    },
  },
} = organizationProjectsGraphQlResponse;

describe('ProjectsView', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    newProjectPath: '/projects/new',
    organizationGid: 'gid://gitlab/Organizations::Organization/1',
  };

  const defaultPropsData = {
    listItemClass: 'gl-px-5',
    search: 'foo',
    sortName: SORT_ITEM_NAME.value,
    sortDirection: SORT_DIRECTION_ASC,
  };

  const projects = {
    nodes,
    pageInfo: pageInfoMultiplePages,
  };

  const successHandler = jest.fn().mockResolvedValue({
    data: {
      organization: {
        id: defaultProvide.organizationGid,
        projects,
      },
    },
  });

  const createComponent = ({ handler = successHandler, propsData = {} } = {}) => {
    mockApollo = createMockApollo([[projectsQuery, handler]]);

    wrapper = shallowMountExtended(ProjectsView, {
      apolloProvider: mockApollo,
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GroupsAndProjectsEmptyState);
  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findNewProjectButton = () => wrapper.findComponent(NewProjectButton);

  afterEach(() => {
    mockApollo = null;
  });

  describe('when API call is loading', () => {
    it('renders loading icon', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    describe.each`
      shouldShowEmptyStateButtons
      ${false}
      ${true}
    `(
      'when there are no projects and `shouldShowEmptyStateButtons` is `$shouldShowEmptyStateButtons`',
      ({ shouldShowEmptyStateButtons }) => {
        const emptyHandler = jest.fn().mockResolvedValue({
          data: {
            organization: {
              id: defaultProvide.organizationGid,
              projects: {
                nodes: [],
                pageInfo: pageInfoEmpty,
              },
            },
          },
        });

        it(`renders empty state ${
          shouldShowEmptyStateButtons ? 'with' : 'without'
        } buttons`, async () => {
          createComponent({
            handler: emptyHandler,
            propsData: { shouldShowEmptyStateButtons },
          });

          await waitForPromises();

          expect(findEmptyState().props()).toMatchObject({
            title: "You don't have any projects yet.",
            description:
              'Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
            svgPath: 'empty-projects-md.svg',
            search: 'foo',
          });

          expect(findNewProjectButton().exists()).toBe(shouldShowEmptyStateButtons);
        });
      },
    );

    describe('when there are projects', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls GraphQL query with correct variables', async () => {
        await waitForPromises();

        expect(successHandler).toHaveBeenCalledWith({
          id: defaultProvide.organizationGid,
          search: defaultPropsData.search,
          sort: 'name_asc',
          last: null,
          first: DEFAULT_PER_PAGE,
          before: null,
          after: null,
        });
      });

      it('renders `ProjectsList` component and passes correct props', async () => {
        await waitForPromises();

        expect(findProjectsList().props()).toMatchObject({
          projects: formatProjects(nodes),
          showProjectIcon: true,
          listItemClass: defaultPropsData.listItemClass,
          timestampType: TIMESTAMP_TYPE_CREATED_AT,
        });
      });
    });

    describe('when there is one page of projects', () => {
      beforeEach(async () => {
        createComponent({
          handler: jest.fn().mockResolvedValue({
            data: {
              organization: {
                id: defaultProvide.organizationGid,
                projects: {
                  nodes,
                  pageInfo: pageInfoOnePage,
                },
              },
            },
          }),
        });
        await waitForPromises();
      });

      it('does not render pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when there is a next page of projects', () => {
      const mockEndCursor = 'mockEndCursor';

      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });

      describe('when next button is clicked', () => {
        beforeEach(() => {
          findPagination().vm.$emit('next', mockEndCursor);
        });

        it('emits `page-change` event', () => {
          expect(wrapper.emitted('page-change')[0]).toEqual([
            {
              endCursor: mockEndCursor,
              startCursor: null,
            },
          ]);
        });
      });

      describe('when `endCursor` prop is changed', () => {
        beforeEach(async () => {
          wrapper.setProps({ endCursor: mockEndCursor });
          await waitForPromises();
        });

        it('calls query with correct variables', () => {
          expect(successHandler).toHaveBeenCalledWith({
            after: mockEndCursor,
            before: null,
            first: DEFAULT_PER_PAGE,
            id: defaultProvide.organizationGid,
            last: null,
            search: defaultPropsData.search,
            sort: 'name_asc',
          });
        });
      });
    });

    describe('when there is a previous page of projects', () => {
      const mockStartCursor = 'mockStartCursor';

      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });

      describe('when next button is clicked', () => {
        beforeEach(() => {
          findPagination().vm.$emit('prev', mockStartCursor);
        });

        it('emits `page-change` event', () => {
          expect(wrapper.emitted('page-change')[0]).toEqual([
            {
              endCursor: null,
              startCursor: mockStartCursor,
            },
          ]);
        });
      });

      describe('when `startCursor` prop is changed', () => {
        beforeEach(async () => {
          wrapper.setProps({ startCursor: mockStartCursor });
          await waitForPromises();
        });

        it('calls query with correct variables', () => {
          expect(successHandler).toHaveBeenCalledWith({
            after: null,
            before: mockStartCursor,
            first: null,
            id: defaultProvide.organizationGid,
            last: DEFAULT_PER_PAGE,
            search: defaultPropsData.search,
            sort: 'name_asc',
          });
        });
      });
    });
  });

  describe('when API call is not successful', () => {
    const error = new Error();

    beforeEach(() => {
      createComponent({ handler: jest.fn().mockRejectedValue(error) });
    });

    it('displays error alert', async () => {
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: ProjectsView.i18n.errorMessage,
        error,
        captureError: true,
      });
    });
  });

  describe('when lists emits refetch', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      findProjectsList().vm.$emit('refetch');
    });

    it('refetches list', () => {
      expect(successHandler).toHaveBeenCalledTimes(2);
    });
  });
});
