import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAvatarLabeled, GlKeysetPagination, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import ReassignedSourceUsers from '~/profile/account/components/reassigned_source_users.vue';
import RevokeReassignmentModal from '~/profile/account/components/revoke_reassignment_modal.vue';
import { createAlert } from '~/alert';

import reassignedSourceUsersQuery from '~/profile/account/graphql/reassigned_source_users.query.graphql';
import revokeSourceUserReassignmentMutation from '~/profile/account/graphql/revoke_source_user_reassignment.mutation.graphql';

import {
  mockReassignedSourceUsers,
  mockReassignedSourceUsersQueryResponse,
  mockRevokeMutationResponse,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('ReassignedSourceUsers', () => {
  let wrapper;

  const sourceUsersQueryHandler = jest
    .fn()
    .mockResolvedValue(mockReassignedSourceUsersQueryResponse());
  const revokeMutationHandler = jest.fn().mockResolvedValue(mockRevokeMutationResponse());

  const createComponent = ({
    mountFn = shallowMountExtended,
    queryHandler = sourceUsersQueryHandler,
    mutationHandler = revokeMutationHandler,
  } = {}) => {
    const mockApollo = createMockApollo([
      [reassignedSourceUsersQuery, queryHandler],
      [revokeSourceUserReassignmentMutation, mutationHandler],
    ]);

    wrapper = mountFn(ReassignedSourceUsers, {
      apolloProvider: mockApollo,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findModal = () => wrapper.findComponent(RevokeReassignmentModal);
  const findRevokeButtons = () => wrapper.findAllByTestId('revoke-button');

  describe('when query is loading', () => {
    it('renders table as loading', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when query fails', () => {
    it('creates an alert', async () => {
      createComponent({
        queryHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Reassigned contributions could not be fetched.',
      });
    });
  });

  describe('when query succeeds', () => {
    beforeEach(async () => {
      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('renders a row for each reassigned source user', () => {
      expect(findTableRows()).toHaveLength(mockReassignedSourceUsers.length);
    });

    it('renders the placeholder user avatar', () => {
      const avatar = findTableRows().at(0).findComponent(GlAvatarLabeled);

      expect(avatar.props()).toMatchObject({
        label: mockReassignedSourceUsers[0].placeholderUser.name,
        subLabel: `@${mockReassignedSourceUsers[0].placeholderUser.username}`,
      });
    });

    it('renders the namespace link', () => {
      const link = findTableRows().at(0).find('a[href="/groups/imported-group"]');

      expect(link.text()).toBe('imported-group');
    });

    it('does not render pagination when there are no other pages', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('pagination', () => {
    let paginatedQueryHandler;

    beforeEach(async () => {
      paginatedQueryHandler = jest.fn().mockResolvedValue(
        mockReassignedSourceUsersQueryResponse({
          pageInfo: { hasNextPage: true },
        }),
      );

      createComponent({ queryHandler: paginatedQueryHandler });
      await waitForPromises();
    });

    it('renders pagination', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('fetches the next page', async () => {
      findPagination().vm.$emit('next');
      await waitForPromises();

      expect(paginatedQueryHandler).toHaveBeenCalledWith(expect.objectContaining({ after: 'end' }));
    });
  });

  describe('revoking a reassignment', () => {
    beforeEach(async () => {
      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('does not show the modal initially', () => {
      expect(findModal().props('visible')).toBe(false);
    });

    it('opens the modal with the selected source user', async () => {
      await findRevokeButtons().at(0).trigger('click');

      expect(findModal().props()).toMatchObject({
        visible: true,
        sourceUser: mockReassignedSourceUsers[0],
      });
    });

    it('calls the revoke mutation when modal confirms', async () => {
      await findRevokeButtons().at(0).trigger('click');
      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(revokeMutationHandler).toHaveBeenCalledWith({
        id: mockReassignedSourceUsers[0].id,
      });
    });

    it('creates an alert when mutation returns errors', async () => {
      createComponent({
        mountFn: mountExtended,
        mutationHandler: jest.fn().mockResolvedValue(
          mockRevokeMutationResponse({
            errors: ['Something went wrong.', 'Something else went wrong.'],
          }),
        ),
      });
      await waitForPromises();

      await findRevokeButtons().at(0).trigger('click');
      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Something else went wrong.',
      });
    });

    it('creates an alert when mutation fails', async () => {
      createComponent({
        mountFn: mountExtended,
        mutationHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      await waitForPromises();

      await findRevokeButtons().at(0).trigger('click');
      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Reassignment could not be revoked.',
      });
    });
  });
});
