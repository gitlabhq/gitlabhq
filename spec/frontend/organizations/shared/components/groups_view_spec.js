import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import { SORT_DIRECTION_ASC, SORT_ITEM_NAME } from '~/organizations/shared/constants';
import NewGroupButton from '~/organizations/shared/components/new_group_button.vue';
import GroupsAndProjectsEmptyState from '~/organizations/shared/components/groups_and_projects_empty_state.vue';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { formatGroups } from '~/organizations/shared/utils';
import {
  renderDeleteSuccessToast,
  deleteParams,
} from 'ee_else_ce/vue_shared/components/resource_lists/utils';
import groupsQuery from '~/organizations/shared/graphql/queries/groups.query.graphql';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { TIMESTAMP_TYPE_CREATED_AT } from '~/vue_shared/components/resource_lists/constants';
import { ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { createAlert } from '~/alert';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  pageInfoMultiplePages,
  pageInfoEmpty,
  pageInfoOnePage,
} from 'jest/organizations/mock_data';

jest.mock(
  '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url',
  () => 'empty-groups-md.svg',
);

const {
  data: {
    organization: {
      groups: { nodes },
    },
  },
} = organizationGroupsGraphQlResponse;

const MOCK_DELETE_PARAMS = {
  testParam: true,
};

jest.mock('ee_else_ce/vue_shared/components/resource_lists/utils', () => ({
  ...jest.requireActual('ee_else_ce/vue_shared/components/resource_lists/utils'),
  renderDeleteSuccessToast: jest.fn(),
  deleteParams: jest.fn(() => MOCK_DELETE_PARAMS),
}));
jest.mock('~/alert');
jest.mock('ee_else_ce/api/groups_api');

Vue.use(VueApollo);

describe('GroupsView', () => {
  let wrapper;
  let mockApollo;
  let mockAxios;

  const defaultProvide = {
    newGroupPath: '/groups/new',
    groupsPath: '/-/organizations/default/groups',
    organizationGid: 'gid://gitlab/Organizations::Organization/1',
  };

  const defaultPropsData = {
    listItemClass: 'gl-px-5',
    search: 'foo',
    sortName: SORT_ITEM_NAME.value,
    sortDirection: SORT_DIRECTION_ASC,
  };

  const groups = {
    nodes,
    pageInfo: pageInfoMultiplePages,
  };

  const successHandler = jest.fn().mockResolvedValue({
    data: {
      organization: {
        id: defaultProvide.organizationGid,
        groups,
      },
    },
  });

  const createComponent = ({ handler = successHandler, propsData = {} } = {}) => {
    mockApollo = createMockApollo([[groupsQuery, handler]]);
    mockAxios = new MockAdapter(axios);

    wrapper = shallowMountExtended(GroupsView, {
      apolloProvider: mockApollo,
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findNewGroupButton = () => wrapper.findComponent(NewGroupButton);
  const findGroupsList = () => wrapper.findComponent(GroupsList);
  const findGroupsListByGroupId = (groupId) =>
    findGroupsList()
      .props('groups')
      .find((group) => group.id === groupId);

  afterEach(() => {
    mockApollo = null;
    mockAxios.restore();
  });

  describe('when API call is loading', () => {
    it('renders loading icon', () => {
      createComponent();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when API call is successful', () => {
    describe.each`
      shouldShowEmptyStateButtons
      ${false}
      ${true}
    `(
      'when there are no groups and `shouldShowEmptyStateButtons` is `$shouldShowEmptyStateButtons`',
      ({ shouldShowEmptyStateButtons }) => {
        const emptyHandler = jest.fn().mockResolvedValue({
          data: {
            organization: {
              id: defaultProvide.organizationGid,
              groups: {
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

          expect(wrapper.findComponent(GroupsAndProjectsEmptyState).props()).toMatchObject({
            title: "You don't have any groups yet.",
            description:
              'A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
            svgPath: 'empty-groups-md.svg',
            search: 'foo',
          });

          expect(findNewGroupButton().exists()).toBe(shouldShowEmptyStateButtons);
        });
      },
    );

    describe('when there are groups', () => {
      beforeEach(() => {
        createComponent({ propsData: {} });
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

      it('renders `GroupsList` component and passes correct props', async () => {
        await waitForPromises();

        expect(findGroupsList().props()).toMatchObject({
          groups: formatGroups(nodes),
          showGroupIcon: true,
          listItemClass: defaultPropsData.listItemClass,
          timestampType: TIMESTAMP_TYPE_CREATED_AT,
        });
      });
    });

    describe('when there is one page of groups', () => {
      beforeEach(async () => {
        createComponent({
          handler: jest.fn().mockResolvedValue({
            data: {
              organization: {
                id: defaultProvide.organizationGid,
                groups: {
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

    describe('when there is a next page of groups', () => {
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
        beforeEach(() => {
          wrapper.setProps({ endCursor: mockEndCursor });
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

    describe('when there is a previous page of groups', () => {
      const mockStartCursor = 'mockStartCursor';

      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });

      describe('when previous button is clicked', () => {
        beforeEach(async () => {
          findPagination().vm.$emit('prev', mockStartCursor);
          await waitForPromises();
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
        message: GroupsView.i18n.errorMessage,
        error,
        captureError: true,
      });
    });
  });

  describe('Deleting group', () => {
    const MOCK_GROUP = formatGroups(nodes)[0];

    describe('when API call is successful', () => {
      beforeEach(async () => {
        createComponent();

        mockAxios.onDelete(defaultProvide.groupsPath).reply(HTTP_STATUS_OK, {});
        await waitForPromises();
      });

      it('calls deleteGroup, properly sets loading state, and refetches list when promise resolves', async () => {
        findGroupsList().vm.$emit('delete', MOCK_GROUP);

        expect(findGroupsListByGroupId(MOCK_GROUP.id).actionLoadingStates[ACTION_DELETE]).toBe(
          true,
        );

        await waitForPromises();
        expect(deleteParams).toHaveBeenCalledWith(MOCK_GROUP);
        expect(mockAxios.history.delete[0].params).toEqual({
          id: MOCK_GROUP.fullPath,
          ...MOCK_DELETE_PARAMS,
        });

        expect(findGroupsListByGroupId(MOCK_GROUP.id).actionLoadingStates[ACTION_DELETE]).toBe(
          false,
        );
        // Refetches list
        expect(successHandler).toHaveBeenCalledTimes(2);
      });

      it('does call renderDeleteSuccessToast', async () => {
        findGroupsList().vm.$emit('delete', MOCK_GROUP);
        await waitForPromises();

        expect(renderDeleteSuccessToast).toHaveBeenCalledWith(MOCK_GROUP, 'Group');
      });

      it('does not call createAlert', async () => {
        findGroupsList().vm.$emit('delete', MOCK_GROUP);
        await waitForPromises();

        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      beforeEach(async () => {
        createComponent();
        mockAxios.onDelete(defaultProvide.groupsPath).networkError();

        await waitForPromises();
      });

      it('calls deleteGroup, properly sets loading state, and shows error alert', async () => {
        findGroupsList().vm.$emit('delete', MOCK_GROUP);

        expect(findGroupsListByGroupId(MOCK_GROUP.id).actionLoadingStates[ACTION_DELETE]).toBe(
          true,
        );

        await waitForPromises();
        expect(deleteParams).toHaveBeenCalledWith(MOCK_GROUP);
        expect(mockAxios.history.delete[0].params).toEqual({
          id: MOCK_GROUP.fullPath,
          ...MOCK_DELETE_PARAMS,
        });

        expect(findGroupsListByGroupId(MOCK_GROUP.id).actionLoadingStates[ACTION_DELETE]).toBe(
          false,
        );

        // Does not refetch list
        expect(successHandler).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred deleting the group. Please refresh the page to try again.',
          error: new Error('Network Error'),
          captureError: true,
        });
      });

      it('does not call renderDeleteSuccessToast', async () => {
        findGroupsList().vm.$emit('delete', MOCK_GROUP);
        await waitForPromises();

        expect(renderDeleteSuccessToast).not.toHaveBeenCalled();
      });
    });
  });
});
