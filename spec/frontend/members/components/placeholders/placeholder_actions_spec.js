import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import PlaceholderActions from '~/members/components/placeholders/placeholder_actions.vue';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all_paginated.query.graphql';
import {
  mockUser1,
  mockUser2,
  mockUsersQueryResponse,
  mockUsersWithPaginationQueryResponse,
} from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('PlaceholderActions', () => {
  let wrapper;
  let mockApollo;

  const usersQueryHandler = jest.fn().mockResolvedValue(mockUsersQueryResponse);

  const createComponent = ({ queryHandler = usersQueryHandler } = {}) => {
    mockApollo = createMockApollo([[searchUsersQuery, queryHandler]]);

    wrapper = shallowMountExtended(PlaceholderActions, {
      apolloProvider: mockApollo,
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDontReassignButton = () => wrapper.findByTestId('dont-reassign-button');
  const findConfirmButton = () => wrapper.findByTestId('confirm-button');

  it('renders listbox with infinite scroll', () => {
    createComponent();

    expect(findListbox().props()).toMatchObject({
      toggleText: 'Select user',
      infiniteScroll: true,
    });
  });

  describe('when users query is loading', () => {
    it('renders listbox as loading', () => {
      createComponent();

      expect(findListbox().props('loading')).toBe(true);
    });
  });

  describe('when users query fails', () => {
    beforeEach(async () => {
      const usersFailedQueryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

      createComponent({
        queryHandler: usersFailedQueryHandler,
      });
      await waitForPromises();
    });

    it('creates an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: 'There was a problem fetching users.' });
    });
  });

  describe('when users query succeeds', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    describe('when "Don\'t reassign" is selected', () => {
      beforeEach(() => {
        findDontReassignButton().vm.$emit('click');
      });

      it('renders listbox with "Don\'t reassign" toggle text', () => {
        expect(findListbox().props('toggleText')).toBe("Don't reassign");
      });

      it('renders confirm button as "Confirm"', () => {
        expect(findConfirmButton().text()).toBe('Confirm');
      });
    });

    describe('when user is selected', () => {
      beforeEach(() => {
        findListbox().vm.$emit('select', mockUser1.id);
      });

      it('renders listbox with @username as toggle text', () => {
        expect(findListbox().props('toggleText')).toBe(`@${mockUser1.username}`);
      });

      it('renders confirm button as "Reassign"', () => {
        expect(findConfirmButton().text()).toBe('Reassign');
      });
    });
  });

  describe('when users query succeeds and has pagination', () => {
    const usersPaginatedQueryHandler = jest.fn();

    beforeEach(async () => {
      usersPaginatedQueryHandler
        .mockResolvedValueOnce(mockUsersWithPaginationQueryResponse)
        .mockResolvedValueOnce(mockUsersQueryResponse);

      createComponent({
        queryHandler: usersPaginatedQueryHandler,
      });
      await waitForPromises();
    });

    describe('when "bottom-reached" event is emitted', () => {
      beforeEach(() => {
        findListbox().vm.$emit('bottom-reached');
      });

      it('calls fetchMore to get next page', () => {
        expect(findListbox().props('infiniteScrollLoading')).toBe(true);

        expect(usersPaginatedQueryHandler).toHaveBeenCalledTimes(2);
        expect(usersPaginatedQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            after: 'end123',
          }),
        );
      });

      it('appends query results to "items"', async () => {
        const allUsers = [mockUser2, mockUser1];

        await waitForPromises();

        expect(findListbox().props('infiniteScrollLoading')).toBe(false);

        const dropdownItems = findListbox().props('items');
        expect(dropdownItems).toHaveLength(allUsers.length);
        dropdownItems.forEach((user, index) => {
          expect(user).toMatchObject({
            id: allUsers[index].id,
            name: allUsers[index].name,
            username: `@${allUsers[index].username}`,
          });
        });
      });
    });
  });
});
