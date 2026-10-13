import { GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTitleCell from '~/work_items/table/components/work_item_title_cell.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { buildWorkItemNode } from '../../board/mock_data';
import { updateWorkItemMutationResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemTitleCell', () => {
  let wrapper;

  const item = buildWorkItemNode(1, {
    title: 'Original title',
    userPermissions: { updateWorkItem: true },
  });
  const itemWithoutEditPermission = buildWorkItemNode(2, {
    title: 'Read-only title',
    userPermissions: { updateWorkItem: false },
  });

  const defaultMutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const mockToast = { show: jest.fn() };

  const findPencilButton = () => wrapper.findByTestId('edit-title-button');
  const findTitleInput = () => wrapper.findComponent(GlFormInput);
  const findTitleLink = () => wrapper.findByTestId('work-item-link');
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);

  const createComponent = ({ props = {}, mutationHandler = defaultMutationHandler } = {}) => {
    const apolloProvider = createMockApollo([[updateWorkItemMutation, mutationHandler]]);

    wrapper = mountExtended(WorkItemTitleCell, {
      apolloProvider,
      propsData: {
        item,
        ...props,
      },
      mocks: {
        $toast: mockToast,
      },
    });
  };

  describe('display mode', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the work item type icon', () => {
      expect(findWorkItemTypeIcon().props()).toMatchObject({
        workItemType: item.workItemType.name,
        typeIconName: item.workItemType.iconName,
      });
    });

    it('renders the title link', () => {
      expect(findTitleLink().exists()).toBe(true);
      expect(findTitleLink().attributes('href')).toBe(item.webPath);
    });

    it('renders the pencil button when user has update permission', () => {
      expect(findPencilButton().exists()).toBe(true);
      expect(findPencilButton().attributes('aria-label')).toBe('Edit title');
    });

    it('does not show the input field', () => {
      expect(findTitleInput().exists()).toBe(false);
    });
  });

  describe('when user cannot update the work item', () => {
    beforeEach(() => {
      createComponent({ props: { item: itemWithoutEditPermission } });
    });

    it('does not render the pencil button', () => {
      expect(findPencilButton().exists()).toBe(false);
    });
  });

  describe('when the item has no work item type', () => {
    beforeEach(() => {
      createComponent({ props: { item: buildWorkItemNode(1, { workItemType: null }) } });
    });

    it('renders the title without the icon', () => {
      expect(findWorkItemTypeIcon().exists()).toBe(false);
      expect(findTitleLink().exists()).toBe(true);
    });
  });

  describe('entering edit mode', () => {
    beforeEach(async () => {
      createComponent();
      await findPencilButton().trigger('click');
    });

    it('hides the title link and pencil button', () => {
      expect(findTitleLink().exists()).toBe(false);
      expect(findPencilButton().exists()).toBe(false);
    });

    it('shows the input field with current title', () => {
      expect(findTitleInput().exists()).toBe(true);
      expect(findTitleInput().props('value')).toBe(item.title);
    });
  });

  describe('canceling edit', () => {
    beforeEach(async () => {
      createComponent();
      await findPencilButton().trigger('click');
    });

    it('cancels on Escape key', async () => {
      await findTitleInput().setValue('Changed title');
      await findTitleInput().trigger('keydown', { key: 'Escape' });

      expect(findTitleInput().exists()).toBe(false);
      expect(findTitleLink().exists()).toBe(true);
    });

    it('prevents Escape key from propagating to parent handlers', async () => {
      const mockParentHandler = jest.fn();
      document.addEventListener('keydown', mockParentHandler);

      await findTitleInput().trigger('keydown', { key: 'Escape' });
      await nextTick();

      expect(mockParentHandler).not.toHaveBeenCalled();

      document.removeEventListener('keydown', mockParentHandler);
    });
  });

  describe('validation', () => {
    beforeEach(async () => {
      createComponent();
      await findPencilButton().trigger('click');
    });

    it('invalidates empty title', async () => {
      await findTitleInput().setValue('');
      await nextTick();

      expect(findTitleInput().props('state')).toBe(false);
    });

    it('invalidates whitespace-only title', async () => {
      await findTitleInput().setValue('   ');
      await nextTick();

      expect(findTitleInput().props('state')).toBe(false);
    });

    it('validates non-empty title', async () => {
      await findTitleInput().setValue('Valid title');
      await nextTick();

      expect(findTitleInput().props('state')).toBe(true);
    });
  });

  describe('saving title', () => {
    it('calls mutation with correct variables when saving via Enter key', async () => {
      const mutationHandler = jest.fn().mockResolvedValue({
        data: {
          workItemUpdate: {
            __typename: 'WorkItemUpdatePayload',
            errors: [],
            workItem: {
              ...item,
              title: 'New title',
            },
          },
        },
      });
      createComponent({ mutationHandler });

      await findPencilButton().trigger('click');
      await nextTick();

      await findTitleInput().setValue('New title');
      await nextTick();

      await findTitleInput().trigger('keydown', { key: 'Enter' });
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledWith({
        input: {
          id: item.id,
          title: 'New title',
        },
        useWorkItemFeatures: false,
      });
    });

    it('calls mutation with correct variables when saving via blur', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
      createComponent({ mutationHandler });

      await findPencilButton().trigger('click');
      await nextTick();

      await findTitleInput().setValue('Changed title');
      await nextTick();

      await findTitleInput().trigger('blur');
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledWith({
        input: {
          id: item.id,
          title: 'Changed title',
        },
        useWorkItemFeatures: false,
      });
    });

    it('does not call mutation when title unchanged', async () => {
      const mutationHandler = jest.fn();
      createComponent({ mutationHandler });

      await findPencilButton().trigger('click');
      await findTitleInput().trigger('keydown', { key: 'Enter' });
      await nextTick();

      expect(mutationHandler).not.toHaveBeenCalled();
    });

    it('does not emit when mutation returns errors', async () => {
      const mutationHandler = jest.fn().mockResolvedValue({
        data: { workItemUpdate: { workItem: null, errors: ['Error updating title'] } },
      });
      createComponent({ mutationHandler });

      await findPencilButton().trigger('click');
      await nextTick();

      await findTitleInput().setValue('New title');
      await nextTick();

      await findTitleInput().trigger('keydown', { key: 'Enter' });
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalled();
      expect(mockToast.show).toHaveBeenCalledWith('Something went wrong while updating the title.');
    });

    it('does not emit when mutation throws error', async () => {
      const mutationHandler = jest.fn().mockRejectedValue(new Error('Network error'));
      createComponent({ mutationHandler });

      await findPencilButton().trigger('click');
      await nextTick();

      await findTitleInput().setValue('New title');
      await nextTick();

      await findTitleInput().trigger('keydown', { key: 'Enter' });
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalled();
      expect(mockToast.show).toHaveBeenCalledWith('Something went wrong while updating the title.');
    });

    it('does not save when Escape is pressed', async () => {
      const mutationHandler = jest.fn();
      createComponent({ mutationHandler });

      await findPencilButton().trigger('click');
      await nextTick();

      await findTitleInput().setValue('New title');
      await nextTick();

      await findTitleInput().trigger('keydown', { key: 'Escape' });
      await nextTick();

      expect(mutationHandler).not.toHaveBeenCalled();
    });
  });
});
