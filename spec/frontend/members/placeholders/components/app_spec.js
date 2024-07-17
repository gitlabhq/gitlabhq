import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import PlaceholdersTabApp from '~/members/placeholders/components/app.vue';
import PlaceholdersTable from '~/members/placeholders/components/placeholders_table.vue';
import importSourceUsersQuery from '~/members/placeholders/graphql/queries/import_source_users.query.graphql';
import { mockSourceUsersQueryResponse } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PlaceholdersTabApp', () => {
  let wrapper;
  let mockApollo;

  const mockGroup = {
    path: 'imported-group',
    name: 'Imported group',
  };
  const sourceUsersQueryHandler = jest.fn().mockResolvedValue(mockSourceUsersQueryResponse());

  const createComponent = ({ queryHandler = sourceUsersQueryHandler } = {}) => {
    mockApollo = createMockApollo([[importSourceUsersQuery, queryHandler]]);

    wrapper = shallowMount(PlaceholdersTabApp, {
      apolloProvider: mockApollo,
      provide: {
        group: mockGroup,
      },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findPlaceholdersTable = () => wrapper.findComponent(PlaceholdersTable);

  it('renders tabs', () => {
    createComponent();

    expect(findTabs().exists()).toBe(true);
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
      const mockSourceUsers = mockSourceUsersQueryResponse().data.namespace.importSourceUsers;

      expect(findPlaceholdersTable().props()).toMatchObject({
        isLoading: false,
        items: mockSourceUsers.nodes,
        pageInfo: mockSourceUsers.pageInfo,
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
