import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlTab, GlTabs } from '@gitlab/ui';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import PlaceholdersTabApp from '~/members/placeholders/components/app.vue';
import PlaceholdersTable from '~/members/placeholders/components/placeholders_table.vue';
import importSourceUsersQuery from '~/members/placeholders/graphql/queries/import_source_users.query.graphql';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import { mockSourceUsersQueryResponse, mockSourceUsers, pagination } from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);
jest.mock('~/alert');

describe('PlaceholdersTabApp', () => {
  let wrapper;
  let store;
  let mockApollo;

  const mockGroup = {
    path: 'imported-group',
    name: 'Imported group',
  };
  const sourceUsersQueryHandler = jest.fn().mockResolvedValue(mockSourceUsersQueryResponse());
  const $toast = {
    show: jest.fn(),
  };

  const createComponent = ({ queryHandler = sourceUsersQueryHandler } = {}) => {
    store = new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.placeholder]: {
          namespaced: true,
          state: {
            pagination,
          },
        },
      },
    });

    mockApollo = createMockApollo([[importSourceUsersQuery, queryHandler]]);

    wrapper = shallowMount(PlaceholdersTabApp, {
      apolloProvider: mockApollo,
      store,
      provide: {
        group: mockGroup,
      },
      mocks: { $toast },
      stubs: { GlTab },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTabAt = (index) => wrapper.findAllComponents(GlTab).at(index);
  const findPlaceholdersTable = () => wrapper.findComponent(PlaceholdersTable);

  it('renders tabs', () => {
    createComponent();

    expect(findTabs().exists()).toBe(true);
  });

  it('renders tab titles with counts', async () => {
    createComponent();
    await nextTick();

    expect(findTabAt(0).text()).toBe(
      `Awaiting reassignment ${pagination.awaitingReassignmentItems}`,
    );
    expect(findTabAt(1).text()).toBe(`Reassigned ${pagination.reassignedItems}`);
  });

  describe('on table "confirm" event', () => {
    const mockSourceUser = mockSourceUsers[1];

    beforeEach(async () => {
      createComponent();
      await nextTick();

      findPlaceholdersTable().vm.$emit('confirm', mockSourceUser);
      await nextTick();
    });

    it('updates tab counts', () => {
      expect(findTabAt(0).text()).toBe(
        `Awaiting reassignment ${pagination.awaitingReassignmentItems - 1}`,
      );
      expect(findTabAt(1).text()).toBe(`Reassigned ${pagination.reassignedItems + 1}`);
    });

    it('shows toast', () => {
      expect($toast.show).toHaveBeenCalledWith(
        'Placeholder Placeholder 2 (@placeholder_2) kept as placeholder.',
      );
    });
  });

  describe('when sourceUsers query is loading', () => {
    it('renders placeholders table as loading', () => {
      createComponent();

      expect(findPlaceholdersTable().props('isLoading')).toBe(true);
    });
  });

  describe('when sourceUsers query fails', () => {
    beforeEach(async () => {
      const sourceUsersFailedQueryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      createComponent({
        queryHandler: sourceUsersFailedQueryHandler,
      });
      await waitForPromises();
    });

    it('creates an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching placeholder users.',
      });
    });
  });

  describe('when sourceUsers query succeeds', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('fetches sourceUsers', () => {
      expect(sourceUsersQueryHandler).toHaveBeenCalledTimes(1);
      expect(sourceUsersQueryHandler).toHaveBeenCalledWith({
        after: null,
        before: null,
        fullPath: mockGroup.path,
        first: 20,
      });
    });

    it('renders placeholders table', () => {
      const sourceUsers = mockSourceUsersQueryResponse().data.namespace.importSourceUsers;

      expect(findPlaceholdersTable().props()).toMatchObject({
        isLoading: false,
        items: sourceUsers.nodes,
        pageInfo: sourceUsers.pageInfo,
      });
    });
  });

  describe('when sourceUsers query succeeds and has pagination', () => {
    const sourceUsersPaginatedQueryHandler = jest.fn();
    const mockPageInfo = {
      endCursor: 'end834',
      hasNextPage: true,
      hasPreviousPage: true,
      startCursor: 'start971',
    };

    beforeEach(async () => {
      sourceUsersPaginatedQueryHandler
        .mockResolvedValueOnce(mockSourceUsersQueryResponse({ pageInfo: mockPageInfo }))
        .mockResolvedValueOnce(mockSourceUsersQueryResponse());

      createComponent({
        queryHandler: sourceUsersPaginatedQueryHandler,
      });
      await waitForPromises();
    });

    describe('when "prev" event is emitted', () => {
      beforeEach(() => {
        findPlaceholdersTable().vm.$emit('prev');
      });

      it('fetches sourceUsers with previous results', () => {
        expect(sourceUsersPaginatedQueryHandler).toHaveBeenCalledTimes(2);
        expect(sourceUsersPaginatedQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            after: null,
            before: mockPageInfo.startCursor,
            last: 20,
          }),
        );
      });
    });

    describe('when "next" event is emitted', () => {
      beforeEach(() => {
        findPlaceholdersTable().vm.$emit('next');
      });

      it('fetches sourceUsers with next results', () => {
        expect(sourceUsersPaginatedQueryHandler).toHaveBeenCalledTimes(2);
        expect(sourceUsersPaginatedQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            after: mockPageInfo.endCursor,
            before: null,
            first: 20,
          }),
        );
      });
    });
  });
});
