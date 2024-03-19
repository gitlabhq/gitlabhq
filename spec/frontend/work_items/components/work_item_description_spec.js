import { GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EditedAt from '~/issues/show/components/edited.vue';
import { updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemDescriptionRendered from '~/work_items/components/work_item_description_rendered.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { autocompleteDataSources, markdownPreviewPath } from '~/work_items/utils';
import {
  groupWorkItemByIidResponseFactory,
  updateWorkItemMutationResponse,
  workItemByIidResponseFactory,
  workItemQueryResponse,
} from '../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/autosave');

const workItemId = workItemQueryResponse.data.workItem.id;

describe('WorkItemDescription', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  let workItemResponseHandler;
  let groupWorkItemResponseHandler;

  const findForm = () => wrapper.findComponent(GlForm);
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findRenderedDescription = () => wrapper.findComponent(WorkItemDescriptionRendered);
  const findEditedAt = () => wrapper.findComponent(EditedAt);

  const editDescription = (newText) => findMarkdownEditor().vm.$emit('input', newText);

  const findCancelButton = () => wrapper.find('[data-testid="cancel"]');
  const findSubmitButton = () => wrapper.find('[data-testid="save-description"]');
  const clickCancel = () => findForm().vm.$emit('reset', new Event('reset'));
  const clickSave = () => findForm().vm.$emit('submit', new Event('submit'));

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    workItemResponse = workItemByIidResponseFactory({ canUpdate }),
    isEditing = false,
    isGroup = false,
    workItemIid = '1',
    disableInlineEditing = false,
    editMode = false,
  } = {}) => {
    workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse);
    groupWorkItemResponseHandler = jest
      .fn()
      .mockResolvedValue(groupWorkItemByIidResponseFactory({ canUpdate }));

    const { id } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemDescription, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemResponseHandler],
        [groupWorkItemByIidQuery, groupWorkItemResponseHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        fullPath: 'test-project-path',
        workItemId: id,
        workItemIid,
        disableInlineEditing,
        editMode,
      },
      provide: {
        isGroup,
      },
    });

    await waitForPromises();

    if (isEditing) {
      findRenderedDescription().vm.$emit('startEditing');

      await nextTick();
    }
  };

  describe('editing description', () => {
    it('passes correct autocompletion data and preview markdown sources and enables quick actions', async () => {
      const {
        iid,
        namespace: { fullPath },
      } = workItemQueryResponse.data.workItem;

      await createComponent({ isEditing: true });

      expect(findMarkdownEditor().props()).toMatchObject({
        supportsQuickActions: true,
        renderMarkdownPath: markdownPreviewPath({ fullPath, iid }),
        autocompleteDataSources: autocompleteDataSources({ fullPath, iid }),
      });
    });
    it('shows edited by text', async () => {
      const lastEditedAt = '2022-09-21T06:18:42Z';
      const lastEditedBy = {
        name: 'Administrator',
        webPath: '/root',
      };

      await createComponent({
        workItemResponse: workItemByIidResponseFactory({ lastEditedAt, lastEditedBy }),
      });

      expect(findEditedAt().props()).toMatchObject({
        updatedAt: lastEditedAt,
        updatedByName: lastEditedBy.name,
        updatedByPath: lastEditedBy.webPath,
      });
    });

    it('does not show edited by text', async () => {
      await createComponent();

      expect(findEditedAt().exists()).toBe(false);
    });

    it('cancels when clicking cancel', async () => {
      await createComponent({
        isEditing: true,
      });

      clickCancel();

      await nextTick();

      expect(confirmAction).not.toHaveBeenCalled();
      expect(findMarkdownEditor().exists()).toBe(false);
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
      const updatedDesc = 'updated desc';

      await createComponent({
        isEditing: true,
      });

      editDescription(updatedDesc);

      clickSave();

      await waitForPromises();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemId,
          descriptionWidget: {
            description: updatedDesc,
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

    it('maps submit and cancel buttons to form actions', async () => {
      await createComponent({
        isEditing: true,
      });

      expect(findCancelButton().attributes('type')).toBe('reset');
      expect(findSubmitButton().attributes('type')).toBe('submit');
    });
  });

  describe('when project context', () => {
    it('calls the project work item query', () => {
      createComponent();

      expect(workItemResponseHandler).toHaveBeenCalled();
    });

    it('skips calling the group work item query', () => {
      createComponent();

      expect(groupWorkItemResponseHandler).not.toHaveBeenCalled();
    });
  });

  describe('when group context', () => {
    it('skips calling the project work item query', () => {
      createComponent({ isGroup: true });

      expect(workItemResponseHandler).not.toHaveBeenCalled();
    });

    it('calls the group work item query', () => {
      createComponent({ isGroup: true });

      expect(groupWorkItemResponseHandler).toHaveBeenCalled();
    });
  });

  describe('when inline editing is disabled', () => {
    describe('when edit mode is inactive', () => {
      beforeEach(() => {
        createComponent({ disableInlineEditing: true });
      });

      it('passes the correct props for work item rendered description', () => {
        expect(findRenderedDescription().props('disableInlineEditing')).toBe(true);
      });

      it('does not show edit mode of markdown editor in default mode', () => {
        expect(findMarkdownEditor().exists()).toBe(false);
      });
    });

    describe('when edit mode is active', () => {
      beforeEach(() => {
        createComponent({ disableInlineEditing: true, editMode: true });
      });

      it('shows markdown editor in edit mode only when the correct props are passed', () => {
        expect(findMarkdownEditor().exists()).toBe(true);
      });

      it('emits the `updateDraft` event when clicked on submit button in edit mode', () => {
        const updatedDesc = 'updated desc with inline editing disabled';
        findMarkdownEditor().vm.$emit('input', updatedDesc);
        expect(wrapper.emitted('updateDraft')).toEqual([[updatedDesc]]);
      });
    });
  });
});
