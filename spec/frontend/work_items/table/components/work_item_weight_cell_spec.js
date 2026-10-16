import { GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemWeightCell from '~/work_items/table/components/work_item_weight_cell.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { buildWorkItemNode, buildWeightWidget } from '../../board/mock_data';

Vue.use(VueApollo);

describe('WorkItemWeightCell', () => {
  let wrapper;
  const mockToast = { show: jest.fn() };

  const item = buildWorkItemNode(1, {
    userPermissions: { updateWorkItem: true },
    widgets: [buildWeightWidget(5)],
  });

  const itemWithoutWeight = buildWorkItemNode(2, {
    userPermissions: { updateWorkItem: true },
    widgets: [buildWeightWidget(null)],
  });

  const itemWithoutEditPermission = buildWorkItemNode(3, {
    userPermissions: { updateWorkItem: false },
    widgets: [buildWeightWidget(3)],
  });

  const weightCellMutationResponse = {
    data: {
      workItemUpdate: {
        __typename: 'WorkItemUpdatePayload',
        errors: [],
        workItem: {
          ...item,
          archived: false,
          imported: false,
          description: null,
          movedToWorkItemUrl: null,
          duplicatedToWorkItemUrl: null,
          promotedToEpicUrl: null,
          showPlanUpgradePromotion: false,
          createNoteEmail: null,
          project: null,
          commentTemplatesPaths: [],
          namespace: {
            ...item.namespace,
            name: 'Group Name',
            fullName: 'Full Group Name',
            webUrl: 'http://gdk.test/group',
          },
          widgets: item.widgets.map((w) =>
            w.type === 'WEIGHT'
              ? { ...w, weight: 10, rolledUpWeight: null, rolledUpCompletedWeight: null }
              : w,
          ),
        },
      },
    },
  };

  const defaultMutationHandler = jest.fn().mockResolvedValue(weightCellMutationResponse);

  const findEditButton = () => wrapper.findByTestId('edit-weight-button');
  const findWeightInput = () => wrapper.findComponent(GlFormInput);
  const findWeightValue = () => wrapper.findByTestId('weight-value');

  const createComponent = ({
    props = {},
    mutationHandler = defaultMutationHandler,
    workItemFeaturesField = false,
  } = {}) => {
    const apolloProvider = createMockApollo([[updateWorkItemMutation, mutationHandler]]);

    wrapper = mountExtended(WorkItemWeightCell, {
      apolloProvider,
      propsData: {
        item,
        ...props,
      },
      provide: {
        glFeatures: { workItemFeaturesField },
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

    it('renders the weight value', () => {
      expect(findWeightValue().text()).toBe('5');
    });

    it('shows edit button when user has update permission', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('does not show the edit input', () => {
      expect(findWeightInput().exists()).toBe(false);
    });

    it('clicking edit button enters edit mode', async () => {
      await findEditButton().trigger('click');

      expect(findWeightInput().exists()).toBe(true);
      expect(findWeightValue().exists()).toBe(false);
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('when work item has no weight', () => {
    beforeEach(() => {
      createComponent({ props: { item: itemWithoutWeight } });
    });

    it('renders empty string', () => {
      expect(findWeightValue().text()).toBe('');
    });

    it('shows edit button when user has permission', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('can enter edit mode', async () => {
      await findEditButton().trigger('click');

      expect(findWeightInput().exists()).toBe(true);
    });
  });

  describe('when user cannot update the work item', () => {
    it('does not show edit button', () => {
      createComponent({ props: { item: itemWithoutEditPermission } });

      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('when work item type does not support weight', () => {
    it('does not show edit button when weight feature is null', () => {
      const incidentItem = buildWorkItemNode(4, {
        userPermissions: { updateWorkItem: true },
        features: { weight: null },
      });

      createComponent({ props: { item: incidentItem } });

      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('when entering edit mode', () => {
    beforeEach(async () => {
      createComponent();
      await findEditButton().trigger('click');
      await nextTick();
    });

    it('hides the weight value and edit button', () => {
      expect(findWeightValue().exists()).toBe(false);
      expect(findEditButton().exists()).toBe(false);
    });

    it('shows the input field', () => {
      expect(findWeightInput().exists()).toBe(true);
    });

    it('shows input with current weight value', () => {
      expect(findWeightInput().element.value).toBe('5');
    });
  });

  describe('when saving weight', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls mutation with correct variables when updating weight', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('10');
      await findWeightInput().trigger('blur');
      await waitForPromises();

      expect(defaultMutationHandler).toHaveBeenCalledWith({
        input: {
          id: item.id,
          weightWidget: {
            weight: 10,
          },
        },
        useWorkItemFeatures: false,
      });
    });

    it('calls mutation to clear weight when input is empty', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('');
      await findWeightInput().trigger('blur');
      await waitForPromises();

      expect(defaultMutationHandler).toHaveBeenCalledWith({
        input: {
          id: item.id,
          weightWidget: {
            weight: null,
          },
        },
        useWorkItemFeatures: false,
      });
    });

    it('does not call mutation when weight unchanged', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().trigger('blur');
      await waitForPromises();

      expect(defaultMutationHandler).not.toHaveBeenCalled();
    });
  });

  describe('when mutation returns errors', () => {
    beforeEach(() => {
      const errorMutationHandler = jest.fn().mockResolvedValue({
        data: {
          workItemUpdate: {
            errors: ['Something went wrong'],
            workItem: null,
          },
        },
      });
      createComponent({ mutationHandler: errorMutationHandler });
    });

    it('shows toast when mutation returns errors', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('10');
      await findWeightInput().trigger('blur');
      await waitForPromises();

      expect(mockToast.show).toHaveBeenCalledWith(
        'Something went wrong while updating the weight.',
      );
    });
  });

  describe('when work_item_features_field is enabled', () => {
    it('sends useWorkItemFeatures: true', async () => {
      createComponent({ workItemFeaturesField: true });

      await findEditButton().trigger('click');
      await findWeightInput().setValue('10');
      await findWeightInput().trigger('blur');
      await waitForPromises();

      expect(defaultMutationHandler).toHaveBeenCalledWith(
        expect.objectContaining({ useWorkItemFeatures: true }),
      );
    });
  });

  describe('validation', () => {
    beforeEach(async () => {
      createComponent();
      await findEditButton().trigger('click');
      await nextTick();
    });

    it('accepts valid positive integers', async () => {
      await findWeightInput().setValue('10');
      expect(findWeightInput().attributes('aria-invalid')).toBeUndefined();
    });

    it('accepts zero', async () => {
      await findWeightInput().setValue('0');
      expect(findWeightInput().attributes('aria-invalid')).toBeUndefined();
    });

    it('accepts empty value', async () => {
      await findWeightInput().setValue('');
      expect(findWeightInput().attributes('aria-invalid')).toBeUndefined();
    });

    it('rejects negative numbers', async () => {
      await findWeightInput().setValue('-5');
      expect(findWeightInput().attributes('aria-invalid')).toBe('true');
    });

    it('rejects decimal numbers', async () => {
      await findWeightInput().setValue('1.5');
      expect(findWeightInput().attributes('aria-invalid')).toBe('true');
    });
  });

  describe('blur with invalid input', () => {
    beforeEach(() => {
      createComponent();
    });

    it('cancels editing when blur occurs with negative number', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('-5');
      await findWeightInput().trigger('blur');
      await nextTick();

      expect(findWeightInput().exists()).toBe(false);
      expect(findWeightValue().exists()).toBe(true);
      expect(findWeightValue().text()).toBe('5');
    });

    it('cancels editing when blur occurs with decimal number', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('1.5');
      await findWeightInput().trigger('blur');
      await nextTick();

      expect(findWeightInput().exists()).toBe(false);
      expect(findWeightValue().exists()).toBe(true);
      expect(findWeightValue().text()).toBe('5');
    });
  });

  describe('keyboard shortcuts', () => {
    beforeEach(() => {
      createComponent();
    });

    it('saves on Enter key', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('10');
      await findWeightInput().trigger('keydown', { key: 'Enter' });
      await waitForPromises();
      await nextTick();

      expect(defaultMutationHandler).toHaveBeenCalledWith({
        input: {
          id: item.id,
          weightWidget: {
            weight: 10,
          },
        },
        useWorkItemFeatures: false,
      });
      expect(findWeightInput().exists()).toBe(false);
    });

    it('does not save when Escape is pressed', async () => {
      await findEditButton().trigger('click');
      await findWeightInput().setValue('10');
      await findWeightInput().trigger('keydown', { key: 'Escape' });
      await nextTick();

      expect(defaultMutationHandler).not.toHaveBeenCalled();
      expect(findWeightInput().exists()).toBe(false);
    });
  });
});
