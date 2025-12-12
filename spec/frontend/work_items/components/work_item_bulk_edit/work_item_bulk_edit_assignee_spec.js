import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  currentUserResponse,
  projectMembersAutocompleteResponseWithCurrentUser,
} from 'jest/work_items/mock_data';
import { createAlert } from '~/alert';
import currentUserQuery from '~/graphql_shared/queries/current_user.query.graphql';
import usersSearchQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import WorkItemBulkEditAssignee from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_assignee.vue';
import { BULK_EDIT_NO_VALUE } from '~/work_items/constants';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemBulkEditAssignee component', () => {
  let wrapper;

  const usersSearchQueryHandler = jest
    .fn()
    .mockResolvedValue(projectMembersAutocompleteResponseWithCurrentUser);
  const currentUserQueryHandler = jest.fn().mockResolvedValue(currentUserResponse);

  const createComponent = ({ props = {}, searchQueryHandler = usersSearchQueryHandler } = {}) => {
    wrapper = mount(WorkItemBulkEditAssignee, {
      apolloProvider: createMockApollo([
        [usersSearchQuery, searchQueryHandler],
        [currentUserQuery, currentUserQueryHandler],
      ]),
      propsData: {
        fullPath: 'group/project',
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
        GlFormGroup: true,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const openListboxAndSelect = async (value) => {
    findListbox().vm.$emit('shown');
    findListbox().vm.$emit('select', value);
    await waitForPromises();
  };

  it('renders the form group', () => {
    createComponent();

    expect(findFormGroup().attributes('label')).toBe('Assignee');
  });

  it('renders a header and reset button', () => {
    createComponent();

    expect(findListbox().props()).toMatchObject({
      headerText: 'Select assignee',
      resetButtonLabel: 'Reset',
    });
  });

  it('resets the selected assignee when the Reset button is clicked', async () => {
    createComponent();

    await openListboxAndSelect('gid://gitlab/User/5');

    expect(findListbox().props('selected')).toBe('gid://gitlab/User/5');

    findListbox().vm.$emit('reset');
    await nextTick();

    expect(findListbox().props('selected')).toEqual([]);
  });

  describe('users query', () => {
    it('is not called before dropdown is shown', () => {
      createComponent();

      expect(usersSearchQueryHandler).not.toHaveBeenCalled();
    });

    it('is called when dropdown is shown', async () => {
      createComponent();

      findListbox().vm.$emit('shown');
      await nextTick();

      expect(usersSearchQueryHandler).toHaveBeenCalled();
    });

    it('emits an error when there is an error in the call', async () => {
      createComponent({ searchQueryHandler: jest.fn().mockRejectedValue(new Error('error!')) });

      findListbox().vm.$emit('shown');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: new Error('error!'),
        message: 'Failed to load assignees. Please try again.',
      });
    });
  });

  describe('listbox items', () => {
    describe('with no selected user', () => {
      it('renders all users with current user Administrator at the top', async () => {
        createComponent();

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual([
          {
            text: 'Unassigned',
            textSrOnly: true,
            options: [{ text: 'Unassigned', value: BULK_EDIT_NO_VALUE }],
          },
          {
            text: 'All',
            textSrOnly: true,
            options: [
              expect.objectContaining({ text: 'Administrator', value: 'gid://gitlab/User/1' }),
              expect.objectContaining({ text: 'rookie', value: 'gid://gitlab/User/5' }),
            ],
          },
        ]);
      });

      it('renders all users with current user Administrator at the top even when current user is not in response', async () => {
        createComponent({
          searchQueryHandler: jest.fn().mockResolvedValue({
            data: {
              workspace: {
                id: 'gid://gitlab/Project/7',
                __typename: 'Project',
                users: [
                  {
                    __typename: 'AutocompletedUser',
                    id: 'gid://gitlab/User/5',
                    avatarUrl: '/avatar2',
                    name: 'rookie',
                    username: 'rookie',
                    webUrl: 'rookie',
                    webPath: '/rookie',
                    status: null,
                    compositeIdentityEnforced: false,
                  },
                ],
              },
            },
          }),
        });

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual([
          {
            text: 'Unassigned',
            textSrOnly: true,
            options: [{ text: 'Unassigned', value: BULK_EDIT_NO_VALUE }],
          },
          {
            text: 'All',
            textSrOnly: true,
            options: [
              expect.objectContaining({ text: 'Administrator', value: 'gid://gitlab/User/1' }),
              expect.objectContaining({ text: 'rookie', value: 'gid://gitlab/User/5' }),
            ],
          },
        ]);
      });
    });

    describe('with selected user', () => {
      it('renders a "Selected" group and an "All" group', async () => {
        createComponent();

        await openListboxAndSelect('gid://gitlab/User/5');

        expect(findListbox().props('items')).toEqual([
          {
            text: 'Unassigned',
            textSrOnly: true,
            options: [{ text: 'Unassigned', value: BULK_EDIT_NO_VALUE }],
          },
          {
            text: 'Selected',
            options: [expect.objectContaining({ text: 'rookie', value: 'gid://gitlab/User/5' })],
          },
          {
            text: 'All',
            textSrOnly: true,
            options: [
              expect.objectContaining({ text: 'Administrator', value: 'gid://gitlab/User/1' }),
            ],
          },
        ]);
      });
    });

    describe('with search', () => {
      it('does not show "Unassigned"', async () => {
        createComponent();

        findListbox().vm.$emit('shown');
        findListbox().vm.$emit('search', 'Admin');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual([
          {
            text: 'All',
            textSrOnly: true,
            options: [
              expect.objectContaining({ text: 'rookie', value: 'gid://gitlab/User/5' }),
              expect.objectContaining({ text: 'Administrator', value: 'gid://gitlab/User/1' }),
            ],
          },
        ]);
      });
    });
  });

  describe('listbox text', () => {
    describe('with no selected user', () => {
      it('renders "Select assignee"', () => {
        createComponent();

        expect(findListbox().props('toggleText')).toBe('Select assignee');
      });
    });

    describe('with selected user', () => {
      it('renders "rookie"', async () => {
        createComponent();

        await openListboxAndSelect('gid://gitlab/User/5');

        expect(findListbox().props('toggleText')).toBe('rookie');
      });
    });

    describe('with unassigned', () => {
      it('renders "Unassigned"', async () => {
        createComponent();

        await openListboxAndSelect(BULK_EDIT_NO_VALUE);

        expect(findListbox().props('toggleText')).toBe('Unassigned');
      });
    });
  });
});
