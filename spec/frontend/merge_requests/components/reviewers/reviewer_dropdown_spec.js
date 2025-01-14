import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import ReviewerDropdown from '~/merge_requests/components/reviewers/reviewer_dropdown.vue';
import UpdateReviewers from '~/merge_requests/components/reviewers/update_reviewers.vue';
import userPermissionsQuery from '~/merge_requests/components/reviewers/queries/user_permissions.query.graphql';
import userAutocompleteWithMRPermissionsQuery from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import setReviewersMutation from '~/merge_requests/components/reviewers/queries/set_reviewers.mutation.graphql';

let wrapper;
let autocompleteUsersMock;
let setReviewersMutationMock;

Vue.use(VueApollo);

const createMockUser = ({ id = 1, name = 'Administrator', username = 'root' } = {}) => ({
  __typename: 'UserCore',
  id: `gid://gitlab/User/${id}`,
  avatarUrl:
    'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
  webUrl: `/${username}`,
  webPath: `/${username}`,
  status: null,
  mergeRequestInteraction: {
    canMerge: true,
  },
  username,
  name,
});

function createComponent(
  adminMergeRequest = true,
  propsData = { selectedReviewers: [createMockUser()] },
) {
  autocompleteUsersMock = jest.fn().mockResolvedValue({
    data: {
      workspace: {
        id: 1,
        users: [createMockUser(), createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' })],
      },
    },
  });
  setReviewersMutationMock = jest.fn().mockResolvedValue({
    data: {
      mergeRequestSetReviewers: {
        errors: [],
      },
    },
  });

  const apolloProvider = createMockApollo(
    [
      [setReviewersMutation, setReviewersMutationMock],
      [userAutocompleteWithMRPermissionsQuery, autocompleteUsersMock],
      [
        userPermissionsQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: { id: 1, mergeRequest: { id: 1, userPermissions: { adminMergeRequest } } },
          },
        }),
      ],
    ],
    {},
    {
      typePolicies: { Query: { fields: { project: { merge: true } } } },
    },
  );

  wrapper = shallowMount(ReviewerDropdown, {
    apolloProvider,
    propsData,
    provide: {
      projectPath: 'gitlab-org/gitlab',
      issuableId: '1',
      issuableIid: '1',
      directlyInviteMembers: true,
    },
    stubs: {
      UpdateReviewers,
    },
  });
}

const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

describe('Reviewer dropdown component', () => {
  describe('when user does not have permission', () => {
    beforeEach(async () => {
      createComponent(false);

      await waitForPromises();
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });
  });

  describe('when user has permission', () => {
    beforeEach(async () => {
      createComponent(true);

      await waitForPromises();
    });

    it('renders dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('tracks the event when edit is clicked', () => {
      const spy = mockTracking('_category_', wrapper.element, jest.spyOn);
      triggerEvent('.js-sidebar-dropdown-toggle');

      expect(spy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
        label: 'right_sidebar',
        property: 'reviewer',
      });
    });

    it('fetches autocomplete users when dropdown opens', () => {
      findDropdown().vm.$emit('shown');

      expect(autocompleteUsersMock).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        mergeRequestId: 'gid://gitlab/MergeRequest/1',
        search: '',
      });
    });

    it('fetches autocomplete users when dropdown searches', () => {
      findDropdown().vm.$emit('search', 'search string');

      expect(autocompleteUsersMock).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        mergeRequestId: 'gid://gitlab/MergeRequest/1',
        search: 'search string',
      });
    });

    describe('with the user already selected', () => {
      it('renders users from autocomplete endpoint and skips "ineligible" pre-selected reviewers', async () => {
        findDropdown().vm.$emit('shown');

        await waitForPromises();

        expect(findDropdown().props('items')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              options: expect.arrayContaining([
                expect.objectContaining({
                  secondaryText: '@bob',
                  text: 'Nonadmin',
                  value: 'bob',
                  mergeRequestInteraction: { canMerge: true },
                }),
              ]),
            }),
          ]),
        );
      });
    });

    describe('with the user not already selected', () => {
      beforeEach(async () => {
        createComponent(true, {});

        await waitForPromises();
      });

      it('renders users from autocomplete endpoint', async () => {
        findDropdown().vm.$emit('shown');

        await waitForPromises();

        expect(findDropdown().props('items')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              options: expect.arrayContaining([
                expect.objectContaining({
                  secondaryText: '@root',
                  text: 'Administrator',
                  value: 'root',
                  mergeRequestInteraction: { canMerge: true },
                }),
                expect.objectContaining({
                  secondaryText: '@bob',
                  text: 'Nonadmin',
                  value: 'bob',
                  mergeRequestInteraction: { canMerge: true },
                }),
              ]),
            }),
          ]),
        );
      });
    });

    it('updates reviewers when dropdown is closed', () => {
      findDropdown().vm.$emit('hidden');

      expect(setReviewersMutationMock).toHaveBeenCalledWith(
        expect.objectContaining({
          reviewerUsernames: ['root'],
        }),
      );
    });
  });

  describe('when users are passed as a prop', () => {
    beforeEach(async () => {
      createComponent(true, { users: [createMockUser()] });

      await waitForPromises();
    });

    it('renders users from autocomplete endpoint', () => {
      expect(findDropdown().props('items')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            options: expect.arrayContaining([
              expect.objectContaining({
                secondaryText: '@root',
                text: 'Administrator',
                value: 'root',
                mergeRequestInteraction: { canMerge: true },
              }),
            ]),
          }),
        ]),
      );
    });

    it('updates reviewers from selected user', async () => {
      findDropdown().vm.$emit('select', ['root']);

      await waitForPromises();

      findDropdown().vm.$emit('hidden');

      await waitForPromises();

      expect(setReviewersMutationMock).toHaveBeenCalledWith(
        expect.objectContaining({
          reviewerUsernames: ['root'],
        }),
      );
    });
  });
});
