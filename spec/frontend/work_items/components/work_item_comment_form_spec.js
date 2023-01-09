import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { updateDraft } from '~/lib/utils/autosave';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import WorkItemCommentForm from '~/work_items/components/work_item_comment_form.vue';
import WorkItemCommentLocked from '~/work_items/components/work_item_comment_locked.vue';
import createNoteMutation from '~/work_items/graphql/create_work_item_note.mutation.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  workItemResponseFactory,
  workItemQueryResponse,
  projectWorkItemResponse,
  createWorkItemNoteResponse,
} from '../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/autosave');

const workItemId = workItemQueryResponse.data.workItem.id;

describe('WorkItemCommentForm', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(createWorkItemNoteResponse);
  const workItemByIidResponseHandler = jest.fn().mockResolvedValue(projectWorkItemResponse);
  let workItemResponseHandler;

  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);

  const setText = (newText) => {
    return findMarkdownEditor().vm.$emit('input', newText);
  };

  const clickSave = () =>
    wrapper
      .findAllComponents(GlButton)
      .filter((button) => button.text().startsWith('Comment'))
      .at(0)
      .vm.$emit('click', {});

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    workItemResponse = workItemResponseFactory({ canUpdate }),
    queryVariables = { id: workItemId },
    fetchByIid = false,
    signedIn = true,
    isEditing = true,
  } = {}) => {
    workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse);

    if (signedIn) {
      window.gon.current_user_id = '1';
      window.gon.current_user_avatar_url = 'avatar.png';
    }

    const { id } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemCommentForm, {
      apolloProvider: createMockApollo([
        [workItemQuery, workItemResponseHandler],
        [createNoteMutation, mutationHandler],
        [workItemByIidQuery, workItemByIidResponseHandler],
      ]),
      propsData: {
        workItemId: id,
        fullPath: 'test-project-path',
        queryVariables,
        fetchByIid,
      },
      stubs: {
        MarkdownField,
        WorkItemCommentLocked,
      },
    });

    await waitForPromises();

    if (isEditing) {
      wrapper.findComponent(GlButton).vm.$emit('click');
    }
  };

  describe('adding a comment', () => {
    it('calls update widgets mutation', async () => {
      const noteText = 'updated desc';

      await createComponent({
        isEditing: true,
        signedIn: true,
      });

      setText(noteText);

      clickSave();

      await waitForPromises();

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          noteableId: workItemId,
          body: noteText,
        },
      });
    });

    it('tracks adding comment', async () => {
      await createComponent();
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      setText('test');

      clickSave();

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'add_work_item_comment', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_comment',
        property: 'type_Task',
      });
    });

    it('emits error when mutation returns error', async () => {
      const error = 'eror';

      await createComponent({
        isEditing: true,
        mutationHandler: jest.fn().mockResolvedValue({
          data: {
            createNote: {
              note: null,
              errors: [error],
            },
          },
        }),
      });

      setText('updated desc');

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

      setText('updated desc');

      clickSave();

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('autosaves', async () => {
      await createComponent({
        isEditing: true,
      });

      setText('updated');

      expect(updateDraft).toHaveBeenCalled();
    });
  });

  it('calls the global ID work item query when `fetchByIid` prop is false', async () => {
    createComponent({ fetchByIid: false });
    await waitForPromises();

    expect(workItemResponseHandler).toHaveBeenCalled();
    expect(workItemByIidResponseHandler).not.toHaveBeenCalled();
  });

  it('calls the IID work item query when when `fetchByIid` prop is true', async () => {
    await createComponent({ fetchByIid: true, isEditing: false });

    expect(workItemResponseHandler).not.toHaveBeenCalled();
    expect(workItemByIidResponseHandler).toHaveBeenCalled();
  });

  it('skips calling the handlers when missing the needed queryVariables', async () => {
    await createComponent({ queryVariables: {}, fetchByIid: false, isEditing: false });

    expect(workItemResponseHandler).not.toHaveBeenCalled();
  });
});
