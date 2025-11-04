import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import ReviewerDropdown from '~/merge_requests/components/reviewers/reviewer_dropdown.vue';
import userPermissionsQuery from '~/merge_requests/components/reviewers/queries/user_permissions.query.graphql';
import userAutocompleteWithMRPermissionsQuery from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import setReviewersMutation from '~/merge_requests/components/reviewers/queries/set_reviewers.mutation.graphql';

const { bindInternalEventDocument } = useMockInternalEventsTracking();

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
  customUsers = null,
) {
  const defaultUsers = [
    createMockUser(),
    createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' }),
  ];
  autocompleteUsersMock = jest.fn().mockResolvedValue({
    data: {
      workspace: {
        id: 1,
        users: customUsers || defaultUsers,
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

    describe('shows current user at top when relevant', () => {
      beforeEach(() => {
        window.gon = {
          current_username: 'currentuser',
          current_user_fullname: 'Current User',
          current_user_avatar_url: 'https://example.com/avatar.jpg',
        };
      });

      afterEach(() => {
        delete window.gon;
      });

      describe('when current user is not selected', () => {
        beforeEach(async () => {
          createComponent(true, { selectedReviewers: [] }, [
            createMockUser(),
            createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' }),
            createMockUser({ id: 3, name: 'Current User', username: 'currentuser' }),
          ]);
          await waitForPromises();

          findDropdown().vm.$emit('shown');
          await waitForPromises();
        });

        it('moves current user to the top of the unselected users list', () => {
          const items = findDropdown().props('items');
          const usersGroup = items.find((group) => group.text === 'Users');

          expect(usersGroup.options[0]).toMatchObject({
            value: 'currentuser',
            text: 'Current User',
            secondaryText: '@currentuser',
          });
        });
      });

      describe('when current user is already selected', () => {
        beforeEach(async () => {
          const currentUser = createMockUser({
            id: 3,
            name: 'Current User',
            username: 'currentuser',
          });

          createComponent(
            true,
            {
              selectedReviewers: [currentUser],
              eligibleReviewers: [currentUser],
            },
            [
              createMockUser(),
              createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' }),
              currentUser,
            ],
          );
          await waitForPromises();

          findDropdown().vm.$emit('shown');
          await waitForPromises();
        });

        it('does not include current user in the unselected users list', () => {
          const items = findDropdown().props('items');
          const usersGroup = items.find((group) => group.text === 'Users');

          expect(usersGroup.options.find((u) => u.value === 'currentuser')).toBeUndefined();
        });

        it('includes current user in the reviewers group', () => {
          const items = findDropdown().props('items');
          const reviewersGroup = items.find((group) => group.text === 'Reviewers');

          expect(reviewersGroup.options.find((u) => u.value === 'currentuser')).toBeDefined();
        });
      });

      describe('when searching', () => {
        beforeEach(async () => {
          createComponent(true, { selectedReviewers: [] }, [
            createMockUser(),
            createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' }),
          ]);
          await waitForPromises();

          autocompleteUsersMock.mockResolvedValueOnce({
            data: {
              workspace: {
                id: 1,
                users: [
                  createMockUser({ id: 3, name: 'Current User', username: 'currentuser' }),
                  createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' }),
                ],
              },
            },
          });

          findDropdown().vm.$emit('search', 'user');
          jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
          await waitForPromises();
        });

        it('does not move current user to the top during search', () => {
          const items = findDropdown().props('items');
          const usersGroup = items.find((group) => group.text === 'Users');
          expect(usersGroup.options[0].value).toBe('currentuser');
          expect(usersGroup.options[1].value).toBe('bob');
        });
      });

      describe('when current user is already first', () => {
        beforeEach(async () => {
          createComponent(true, { selectedReviewers: [] }, [
            createMockUser({ id: 3, name: 'Current User', username: 'currentuser' }),
            createMockUser(),
            createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' }),
          ]);
          await waitForPromises();

          findDropdown().vm.$emit('shown');
          await waitForPromises();
        });

        it('maintains current user at the top without reordering', () => {
          const items = findDropdown().props('items');
          const usersGroup = items.find((group) => group.text === 'Users');

          expect(usersGroup.options[0]).toMatchObject({
            value: 'currentuser',
            text: 'Current User',
          });
        });
      });
    });

    it('updates reviewers when dropdown is closed', async () => {
      findDropdown().vm.$emit('hidden');

      await waitForPromises();

      expect(setReviewersMutationMock).toHaveBeenCalledWith(
        expect.objectContaining({
          reviewerUsernames: ['root'],
          projectPath: 'gitlab-org/gitlab',
          iid: '1',
        }),
      );
    });

    describe('tracking when the dropdown is closed', () => {
      let trackEventSpy;

      beforeEach(async () => {
        createComponent(true, {
          users: [createMockUser(), createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' })],
        });

        await waitForPromises();

        ({ trackEventSpy } = bindInternalEventDocument(wrapper.element));
      });

      it('tracks which position any selected users were in as a telemetry event', async () => {
        findDropdown().vm.$emit('select', ['root']);
        findDropdown().vm.$emit('hidden');

        await waitForPromises();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'user_selects_reviewer_from_mr_sidebar',
          {
            value: 1,
            suggested_position: 0,
            selectable_reviewers_count: 2,
          },
          undefined,
        );
      });

      it('tracks which position any selected users were in - discounting already selected reviewers - as a telemetry event', async () => {
        createComponent(true, {
          users: [createMockUser(), createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' })],
          selectedReviewers: [createMockUser()],
        });

        await waitForPromises();

        findDropdown().vm.$emit('select', ['bob']);
        findDropdown().vm.$emit('hidden');

        await waitForPromises();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'user_selects_reviewer_from_mr_sidebar',
          {
            value: 1,
            suggested_position: 0,
            selectable_reviewers_count: 1,
          },
          undefined,
        );
      });

      it('tracks which position any selected users were in after a search as a telemetry event', async () => {
        findDropdown().vm.$emit('search', 'bob');
        findDropdown().vm.$emit('select', ['bob']);
        findDropdown().vm.$emit('hidden');

        await waitForPromises();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'user_selects_reviewer_from_mr_sidebar_after_search',
          {
            value: 2,
            suggested_position: 0,
            selectable_reviewers_count: 2,
          },
          undefined,
        );
      });

      it('does not send the "simple sidebar" tracking event when used "normally" (in complex mode)', async () => {
        findDropdown().vm.$emit('select', ['bob']);
        findDropdown().vm.$emit('hidden');

        await waitForPromises();

        expect(trackEventSpy).not.toHaveBeenCalledWith(
          'user_requests_review_from_mr_simple_sidebar',
          {},
          undefined,
        );
      });

      describe('simple sidebar usage (without using the reviewers panel)', () => {
        it('sends the "simple sidebar" tracking event', async () => {
          createComponent(true, {
            users: [createMockUser(), createMockUser({ id: 2, name: 'Nonadmin', username: 'bob' })],
            usage: 'simple',
          });

          await waitForPromises();

          findDropdown().vm.$emit('select', ['bob']);
          findDropdown().vm.$emit('hidden');

          await waitForPromises();

          expect(trackEventSpy).toHaveBeenCalledWith(
            'user_requests_review_from_mr_simple_sidebar',
            {},
            undefined,
          );
        });
      });

      describe('"suggested" historical position', () => {
        it('reports the correct prior suggested position', async () => {
          createComponent(true, {
            selectedReviewers: [],
          });

          await waitForPromises();

          findDropdown().vm.$emit('shown');

          await waitForPromises();

          findDropdown().vm.$emit('select', ['root']);
          findDropdown().vm.$emit('hidden');

          await waitForPromises();

          expect(trackEventSpy).toHaveBeenCalledWith(
            'user_selects_reviewer_from_mr_sidebar',
            {
              value: 1,
              suggested_position: 1,
              selectable_reviewers_count: 2,
            },
            undefined,
          );
        });

        it('reports the correct prior suggested position - discounting already selected reviewers', async () => {
          createComponent(true, {
            selectedReviewers: [createMockUser()],
          });

          await waitForPromises();

          findDropdown().vm.$emit('shown');

          await waitForPromises();

          findDropdown().vm.$emit('select', ['bob']);
          findDropdown().vm.$emit('hidden');

          await waitForPromises();

          expect(trackEventSpy).toHaveBeenCalledWith(
            'user_selects_reviewer_from_mr_sidebar',
            {
              value: 1,
              suggested_position: 1,
              selectable_reviewers_count: 1,
            },
            undefined,
          );
        });

        it("reports 0 as the prior suggested position of the reviewer if they weren't in the initial suggested list", async () => {
          createComponent(true, {
            selectedReviewers: [],
          });

          await waitForPromises();

          findDropdown().vm.$emit('shown');
          await waitForPromises();

          autocompleteUsersMock.mockReset();
          autocompleteUsersMock.mockResolvedValue({
            data: {
              workspace: {
                id: 1,
                users: [createMockUser({ id: 3, name: 'Friend', username: 'coolguy' })],
              },
            },
          });
          findDropdown().vm.$emit('search', 'coolguy');
          jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
          await waitForPromises();

          findDropdown().vm.$emit('select', ['coolguy']);
          findDropdown().vm.$emit('hidden');

          await waitForPromises();

          expect(trackEventSpy).toHaveBeenCalledWith(
            'user_selects_reviewer_from_mr_sidebar_after_search',
            {
              value: 1,
              suggested_position: 0,
              selectable_reviewers_count: 1,
            },
            undefined,
          );
        });
      });
    });

    describe('multipleSelectionEnabled prop', () => {
      describe('when multipleSelectionEnabled is false (default)', () => {
        beforeEach(async () => {
          createComponent(true, { selectedReviewers: [createMockUser()] });
          await waitForPromises();
        });

        it('sets multiple prop to false on listbox', () => {
          expect(findDropdown().props('multiple')).toBe(false);
        });

        it('normalizes selected reviewers to a single string value', () => {
          expect(findDropdown().props('selected')).toBe('root');
        });

        it('shows "Unassign" as reset button label', () => {
          expect(findDropdown().props('resetButtonLabel')).toBe('Unassign');
        });
      });

      describe('when multipleSelectionEnabled is true', () => {
        beforeEach(async () => {
          createComponent(true, {
            selectedReviewers: [createMockUser()],
            multipleSelectionEnabled: true,
          });
          await waitForPromises();
        });

        it('sets multiple prop to true on listbox', () => {
          expect(findDropdown().props('multiple')).toBe(true);
        });

        it('normalizes selected reviewers to an array', () => {
          expect(findDropdown().props('selected')).toEqual(['root']);
        });

        it('shows "Unassign all" as reset button label', () => {
          expect(findDropdown().props('resetButtonLabel')).toBe('Unassign all');
        });
      });
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

      findDropdown().vm.$emit('hidden');

      await waitForPromises();

      expect(setReviewersMutationMock).toHaveBeenCalledWith(
        expect.objectContaining({
          reviewerUsernames: ['root'],
          projectPath: 'gitlab-org/gitlab',
          iid: '1',
        }),
      );
    });
  });
});
