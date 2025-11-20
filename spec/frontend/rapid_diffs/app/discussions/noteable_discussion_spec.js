import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { merge } from 'lodash';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';
import NoteableDiscussion from '~/rapid_diffs/app/discussions/noteable_discussion.vue';
import DiscussionNotes from '~/rapid_diffs/app/discussions/discussion_notes.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/secret_detection');
jest.mock('~/lib/utils/common_utils');

describe('NoteableDiscussion', () => {
  let wrapper;
  let axiosMock;
  let defaultProps;

  const createDiscussion = () => ({
    id: 'discussion-1',
    reply_id: 'reply-1',
    internal: false,
    notes: [{ id: 'note-1', internal: false }],
  });

  const defaultProvide = {
    userPermissions: { can_create_note: true },
    endpoints: { createNote: '/api/notes' },
  };

  const createComponent = ({ props = {}, provide = {}, repliesVisible = true } = {}) => {
    wrapper = shallowMount(NoteableDiscussion, {
      propsData: {
        ...defaultProps,
        discussion: createDiscussion(),
        ...props,
      },
      provide: merge(defaultProvide, provide),
      stubs: {
        DiscussionNotes: stubComponent(DiscussionNotes, {
          data() {
            return { repliesVisible };
          },
          template: `<ul><slot name="footer" :repliesVisible="repliesVisible"></slot></ul>`,
        }),
      },
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
    axiosMock = new AxiosMockAdapter(axios);
    defaultProps = {
      requestLastNoteEditing: jest.fn(),
    };
  });

  it('renders timeline entry item', () => {
    createComponent();
    expect(wrapper.findComponent(TimelineEntryItem).exists()).toBe(true);
  });

  it('renders discussion notes', () => {
    createComponent();
    expect(wrapper.findComponent(DiscussionNotes).props('notes')).toStrictEqual(
      createDiscussion().notes,
    );
  });

  it('renders signed out widget when not logged in', () => {
    isLoggedIn.mockReturnValue(false);
    createComponent();
    expect(wrapper.findComponent(NoteSignedOutWidget).exists()).toBe(true);
  });

  it('renders reply placeholder when not replying and user can create notes', () => {
    createComponent();
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(true);
    expect(wrapper.findComponent(NoteForm).exists()).toBe(false);
  });

  it('starts replying', async () => {
    createComponent();
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(false);
    expect(wrapper.emitted('showReplyForm')).toStrictEqual([[]]);
  });

  it('shows note form when startReplying is emitted', async () => {
    createComponent();
    await wrapper.findComponent(DiscussionNotes).vm.$emit('startReplying');
    await nextTick();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(false);
    expect(wrapper.emitted('showReplyForm')).toStrictEqual([[]]);
  });

  it('hides note form when cancelled without confirmation', async () => {
    createComponent();
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    await wrapper.findComponent(NoteForm).vm.$emit('cancel', false, false);
    await nextTick();
    expect(confirmAction).not.toHaveBeenCalled();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(false);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(true);
  });

  it('shows confirmation when form is dirty', async () => {
    confirmAction.mockResolvedValue(true);
    createComponent();
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    await wrapper.findComponent(NoteForm).vm.$emit('cancel', true, true);
    expect(confirmAction).toHaveBeenCalled();
    await waitForPromises();
    await nextTick();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(false);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(true);
  });

  it('does not hide form when confirmation is declined', async () => {
    confirmAction.mockResolvedValue(false);
    createComponent();
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    await wrapper.findComponent(NoteForm).vm.$emit('cancel', true, true);
    await nextTick();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(false);
  });

  it('propagates noteUpdated event', () => {
    const note = {};
    createComponent();
    wrapper.findComponent(DiscussionNotes).vm.$emit('noteUpdated', note);
    expect(wrapper.emitted('noteUpdated')).toStrictEqual([[note]]);
  });

  it('propagates noteDeleted event', () => {
    const note = {};
    createComponent();
    wrapper.findComponent(DiscussionNotes).vm.$emit('noteDeleted', note);
    expect(wrapper.emitted('noteDeleted')).toStrictEqual([[note]]);
  });

  it('propagates startEditing event', () => {
    const note = {};
    createComponent();
    wrapper.findComponent(DiscussionNotes).vm.$emit('startEditing', note);
    expect(wrapper.emitted('startEditing')).toStrictEqual([[note]]);
  });

  it('propagates cancelEditing event', () => {
    const note = {};
    createComponent();
    wrapper.findComponent(DiscussionNotes).vm.$emit('cancelEditing', note);
    expect(wrapper.emitted('cancelEditing')).toStrictEqual([[note]]);
  });

  describe('when saving reply', () => {
    beforeEach(() => {
      detectAndConfirmSensitiveTokens.mockResolvedValue(true);
    });

    it('adds reply', async () => {
      const note = {};
      axiosMock.onPost(defaultProvide.endpoints.createNote).reply(HTTP_STATUS_OK, { note });
      createComponent();
      await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
      await nextTick();
      await wrapper.findComponent(NoteForm).props('saveNote')('test note');
      expect(wrapper.emitted('replyAdded')).toStrictEqual([[note]]);
    });

    it('hides note form after successful save', async () => {
      const note = {};
      axiosMock.onPost(defaultProvide.endpoints.createNote).reply(HTTP_STATUS_OK, { note });
      createComponent();
      await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
      await nextTick();
      await wrapper.findComponent(NoteForm).props('saveNote')('test note');
      await nextTick();
      expect(wrapper.findComponent(NoteForm).exists()).toBe(false);
    });

    it('does not save when sensitive token detection is declined', async () => {
      detectAndConfirmSensitiveTokens.mockResolvedValue(false);
      createComponent();
      await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
      await nextTick();
      await wrapper.findComponent(NoteForm).props('saveNote')('test note');
      expect(wrapper.emitted('replyAdded')).toBe(undefined);
    });

    it('shows alert when save fails', async () => {
      axiosMock
        .onPost(defaultProvide.endpoints.createNote)
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();
      await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
      try {
        await wrapper.findComponent(NoteForm).props('saveNote')('test note');
      } catch (error) {
        expect(error).toBeInstanceOf(Error);
      }
      expect(createAlert).toHaveBeenCalled();
      expect(wrapper.emitted('replyAdded')).toBe(undefined);
    });
  });

  it('passes data to form', async () => {
    const requestLastNoteEditing = jest.fn();
    const discussion = createDiscussion();
    createComponent({ props: { discussion, requestLastNoteEditing } });
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    const props = wrapper.findComponent(NoteForm).props();
    props.requestLastNoteEditing();
    expect(props.saveButtonTitle).toBe('Reply');
    expect(props.autosaveKey).toBeDefined();
    expect(props.internal).toBe(false);
    expect(requestLastNoteEditing).toHaveBeenCalledWith(discussion);
  });

  it('passes correct saveButtonTitle for internal discussion', async () => {
    createComponent({ props: { discussion: { ...createDiscussion(), internal: true } } });
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    const props = wrapper.findComponent(NoteForm).props();
    expect(props.saveButtonTitle).toBe('Reply internally');
    expect(props.internal).toBe(true);
  });
});
