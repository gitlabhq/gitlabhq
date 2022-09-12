import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import {
  updateWorkItemMutationResponse,
  workItemResponseFactory,
  workItemQueryResponse,
} from '../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => {
  return {
    confirmAction: jest.fn(),
  };
});
jest.mock('~/lib/utils/autosave');

const workItemId = workItemQueryResponse.data.workItem.id;

describe('WorkItemDescription', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findEditButton = () => wrapper.find('[data-testid="edit-description"]');
  const findMarkdownField = () => wrapper.findComponent(MarkdownField);

  const editDescription = (newText) => wrapper.find('textarea').setValue(newText);

  const clickCancel = () => wrapper.find('[data-testid="cancel"]').vm.$emit('click');
  const clickSave = () => wrapper.find('[data-testid="save-description"]').vm.$emit('click', {});

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    isEditing = false,
  } = {}) => {
    const workItemResponse = workItemResponseFactory({ canUpdate });
    const workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse);

    const { id } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemDescription, {
      apolloProvider: createMockApollo([
        [workItemQuery, workItemResponseHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        workItemId: id,
        fullPath: 'test-project-path',
      },
      stubs: {
        MarkdownField,
      },
    });

    await waitForPromises();

    if (isEditing) {
      findEditButton().vm.$emit('click');

      await nextTick();
    }
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Edit button', () => {
    it('is not visible when canUpdate = false', async () => {
      await createComponent({
        canUpdate: false,
      });

      expect(findEditButton().exists()).toBe(false);
    });

    it('toggles edit mode', async () => {
      await createComponent({
        canUpdate: true,
      });

      findEditButton().vm.$emit('click');

      await nextTick();

      expect(findMarkdownField().exists()).toBe(true);
    });
  });

  describe('editing description', () => {
    it('cancels when clicking cancel', async () => {
      await createComponent({
        isEditing: true,
      });

      clickCancel();

      await nextTick();

      expect(confirmAction).not.toHaveBeenCalled();
      expect(findMarkdownField().exists()).toBe(false);
    });

    it('prompts for confirmation when clicking cancel after changes', async () => {
      await createComponent({
        isEditing: true,
      });

      editDescription('updated desc');

      clickCancel();

      await nextTick();

      expect(confirmAction).toHaveBeenCalled();
    });

    it('calls update widgets mutation', async () => {
      await createComponent({
        isEditing: true,
      });

      editDescription('updated desc');

      clickSave();

      await waitForPromises();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemId,
          descriptionWidget: {
            description: 'updated desc',
          },
        },
      });
    });

    it('tracks editing description', async () => {
      await createComponent({
        isEditing: true,
        markdownPreviewPath: '/preview',
      });
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      clickSave();

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_description', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_description',
        property: 'type_Task',
      });
    });

    it('emits error when mutation returns error', async () => {
      const error = 'eror';

      await createComponent({
        isEditing: true,
        mutationHandler: jest.fn().mockResolvedValue({
          data: {
            workItemUpdate: {
              workItem: {},
              errors: [error],
            },
          },
        }),
      });

      editDescription('updated desc');

      clickSave();

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('emits error when mutation fails', async () => {
      const error = 'eror';

      await createComponent({
        isEditing: true,
        mutationHandler: jest.fn().mockRejectedValue(new Error(error)),
      });

      editDescription('updated desc');

      clickSave();

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('autosaves description', async () => {
      await createComponent({
        isEditing: true,
      });

      editDescription('updated desc');

      expect(updateDraft).toHaveBeenCalled();
    });
  });
});
