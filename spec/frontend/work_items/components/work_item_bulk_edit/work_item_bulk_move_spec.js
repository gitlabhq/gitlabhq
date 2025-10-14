import { mount } from '@vue/test-utils';
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import WorkItemBulkMove from '~/work_items/components/work_item_bulk_edit/work_item_bulk_move.vue';
import searchUserProjectsWithIssuesEnabledQuery from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_projects_with_issues_enabled.query.graphql';
import searchOrganizationProjectsWithIssuesEnabled from '~/work_items/graphql/get_organization_project_to_move.query.graphql';
import moveMutation from '~/work_items/graphql/list/work_item_bulk_move.mutation.graphql';
import { searchUserProjectsResponse, searchOrganizationProjectsResponse } from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('WorkItemBulkMove', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;

  const mockCheckedItems = [
    {
      id: 'gid://gitlab/WorkItem/11',
      title: 'Work Item 11',
      workItemType: { id: 'gid://gitlab/WorkItems::Type/8' },
    },
    {
      id: 'gid://gitlab/WorkItem/22',
      title: 'Work Item 22',
      workItemType: { id: 'gid://gitlab/WorkItems::Type/5' },
    },
  ];

  const destinationNamespacesResolver = jest.fn().mockResolvedValue(searchUserProjectsResponse);
  const organizationDestinationResolver = jest
    .fn()
    .mockResolvedValue(searchOrganizationProjectsResponse);

  const moveMutationHandler = jest.fn().mockResolvedValue({
    data: {
      workItemBulkMove: {
        movedWorkItemCount: 2,
        errors: [],
      },
    },
  });

  const createComponent = ({
    checkedItems = mockCheckedItems,
    disabled = false,
    destinationsResolver = destinationNamespacesResolver,
    organizationResolver = organizationDestinationResolver,
    moveHandler = moveMutationHandler,
    currentOrganization = null,
  } = {}) => {
    window.gon = {
      current_organization: currentOrganization,
    };

    wrapper = mount(WorkItemBulkMove, {
      apolloProvider: createMockApollo([
        [searchUserProjectsWithIssuesEnabledQuery, destinationsResolver],
        [searchOrganizationProjectsWithIssuesEnabled, organizationResolver],
        [moveMutation, moveHandler],
      ]),
      propsData: {
        fullPath: 'gitlab-org/gitlab',
        checkedItems,
        disabled,
      },
      stubs: {
        GlCollapsibleListbox,
        GlFormGroup: true,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findButton = () => wrapper.find('[data-testid="submit-move-button"]');
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);

  it('renders a listbox', () => {
    createComponent();
    expect(findListbox().exists()).toBe(true);
  });

  it('renders a button', () => {
    createComponent();
    expect(findButton().exists()).toBe(true);
  });

  it('renders a form group', () => {
    createComponent();
    expect(findFormGroup().exists()).toBe(true);
    expect(findFormGroup().attributes('label')).toBe('Move');
  });

  describe('destination list', () => {
    describe('when there are no checked items', () => {
      it('is disabled', () => {
        createComponent({ checkedItems: [] });
        expect(findListbox().props('disabled')).toBe(true);
      });
    });

    describe('when the "disabled" prop is `true`', () => {
      it('is disabled', () => {
        createComponent({ disabled: true });
        expect(findListbox().props('disabled')).toBe(true);
      });
    });

    describe('when there are checked items', () => {
      it('does not make a request on mount', async () => {
        createComponent();
        await waitForPromises();
        expect(destinationNamespacesResolver).not.toHaveBeenCalled();
      });

      describe('without organization', () => {
        it('fetches destination list using user projects query when opened', async () => {
          createComponent();
          findListbox().vm.$emit('shown');
          await waitForPromises();
          expect(destinationNamespacesResolver).toHaveBeenCalledWith({
            search: '',
          });
          expect(organizationDestinationResolver).not.toHaveBeenCalled();
        });
      });

      describe('with organization', () => {
        const mockOrganization = { id: '1' };

        it('fetches destination list using organization projects query when opened', async () => {
          createComponent({ currentOrganization: mockOrganization });
          findListbox().vm.$emit('shown');
          await waitForPromises();
          expect(organizationDestinationResolver).toHaveBeenCalledWith({
            search: '',
            organizationId: 'gid://gitlab/Organizations::Organization/1',
          });
          expect(destinationNamespacesResolver).not.toHaveBeenCalled();
        });
      });

      it('creates an alert when unable to fetch destinations', async () => {
        const errorResolver = jest.fn().mockRejectedValue(new Error('uh oh!'));
        createComponent({ destinationsResolver: errorResolver });
        findListbox().vm.$emit('shown');
        await waitForPromises();
        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('uh oh!'),
          message: 'Unable to fetch destination projects.',
        });
      });

      it('displays selected destination in toggle', async () => {
        createComponent();
        findListbox().vm.$emit('shown');
        await waitForPromises();
        findListbox().vm.$emit('select', 'gid://gitlab/Project/1');
        await nextTick();
        expect(findListbox().props('toggleText')).toBe('Group A / Example project A');
      });
    });
  });

  describe('move button', () => {
    describe('when there are no checked items', () => {
      beforeEach(() => {
        createComponent({ checkedItems: [] });
      });

      it('is disabled', () => {
        expect(findButton().props('disabled')).toBe(true);
      });

      it('says no items selected', () => {
        expect(findButton().text()).toBe('No items selected');
      });
    });

    describe('when there is no destination selected', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is disabled', () => {
        expect(findButton().props('disabled')).toBe(true);
      });

      it('says no destination selected', () => {
        expect(findButton().text()).toBe('No destination selected');
      });
    });

    describe('when there is a destination selected', () => {
      beforeEach(async () => {
        createComponent();
        findListbox().vm.$emit('shown');
        await waitForPromises();
        findListbox().vm.$emit('select', 'gid://gitlab/Project/1');
        return nextTick();
      });

      it('is not disabled', () => {
        expect(findButton().props('disabled')).toBe(false);
      });

      it('says move', async () => {
        expect(findButton().text()).toBe('Move 2 items');

        await wrapper.setProps({ checkedItems: [mockCheckedItems[0]] });

        expect(findButton().text()).toBe('Move item');
      });
    });
  });

  describe('moving items', () => {
    beforeEach(async () => {
      createComponent();
      findListbox().vm.$emit('shown');
      await waitForPromises();
      findListbox().vm.$emit('select', 'gid://gitlab/Project/1');
      findButton().vm.$emit('click');
    });

    it('emits "moveStart" event when the button is clicked', () => {
      expect(wrapper.emitted('moveStart')).toHaveLength(1);
    });

    it('calls the bulk edit mutation with the correct variables', async () => {
      await waitForPromises();
      expect(moveMutationHandler).toHaveBeenCalledWith({
        input: {
          ids: ['gid://gitlab/WorkItem/11', 'gid://gitlab/WorkItem/22'],
          sourceFullPath: 'gitlab-org/gitlab',
          targetFullPath: 'group-a/example-project-a',
        },
      });
    });

    describe('on success', () => {
      it('emits "moveSuccess" event with toast message', async () => {
        await waitForPromises();
        const events = wrapper.emitted('moveSuccess');
        expect(events).toHaveLength(1);
        expect(events[0][0]).toEqual({ toastMessage: 'Moved 2 of 2 items' });
      });

      it('emits "moveFinished" event', async () => {
        await waitForPromises();
        expect(wrapper.emitted('moveFinish')).toHaveLength(1);
      });
    });

    describe('on partial success', () => {
      const partialSuccessMoveHandler = jest.fn().mockResolvedValue({
        data: {
          workItemBulkMove: {
            movedWorkItemCount: 1,
            errors: [],
          },
        },
      });

      beforeEach(async () => {
        createComponent({ moveHandler: partialSuccessMoveHandler });
        findListbox().vm.$emit('shown');
        await waitForPromises();
        findListbox().vm.$emit('select', 'gid://gitlab/Project/1');
        findButton().vm.$emit('click');
      });

      it('emits "moveSuccess" event with toast message', async () => {
        await waitForPromises();
        const events = wrapper.emitted('moveSuccess');
        expect(events).toHaveLength(1);
        expect(events[0][0]).toEqual({ toastMessage: 'Moved 1 of 2 items' });
      });

      it('emits "moveFinished" event', async () => {
        await waitForPromises();
        expect(wrapper.emitted('moveFinish')).toHaveLength(1);
      });
    });

    describe('on network error', () => {
      const errorMoveHandler = jest.fn().mockRejectedValue(new Error('Something went wrong!'));

      beforeEach(async () => {
        createComponent({ moveHandler: errorMoveHandler });
        findListbox().vm.$emit('shown');
        await waitForPromises();
        findListbox().vm.$emit('select', 'gid://gitlab/Project/1');
        findButton().vm.$emit('click');
        await waitForPromises();
      });

      it('creates an alert for the error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('Something went wrong!'),
          message: 'Something went wrong while bulk editing.',
        });
      });

      it('emits "moveFinished" event', () => {
        expect(wrapper.emitted('moveFinish')).toHaveLength(1);
      });
    });

    describe('on GraphQL error', () => {
      const grapgQlErrorMoveHandler = jest.fn().mockResolvedValue({
        data: {
          workItemBulkMove: {
            movedWorkItemCount: 0,
            errors: ['Something went wrong!'],
          },
        },
      });

      beforeEach(async () => {
        createComponent({ moveHandler: grapgQlErrorMoveHandler });
        findListbox().vm.$emit('shown');
        await waitForPromises();
        findListbox().vm.$emit('select', 'gid://gitlab/Project/1');
        findButton().vm.$emit('click');
        await waitForPromises();
      });

      it('creates an alert for the error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('Something went wrong!'),
          message: 'Something went wrong while bulk editing.',
        });
      });

      it('emits "moveFinished" event', () => {
        expect(wrapper.emitted('moveFinish')).toHaveLength(1);
      });
    });
  });
});
