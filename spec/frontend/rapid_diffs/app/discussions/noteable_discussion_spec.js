import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { merge } from 'lodash-es';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { createAlert } from '~/alert';
import { COMMENT_FORM } from '~/notes/i18n';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import ResolveDiscussionButton from '~/notes/components/resolve_discussion_button.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';
import NoteableDiscussion from '~/rapid_diffs/app/discussions/noteable_discussion.vue';
import DiscussionNotes from '~/rapid_diffs/app/discussions/discussion_notes.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/secret_detection');
jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/autosave');

describe('NoteableDiscussion', () => {
  let wrapper;
  let defaultProps;
  let store;

  const createDiscussion = (discussionProps, noteProps) => ({
    id: 'discussion-1',
    reply_id: 'reply-1',
    internal: false,
    notes: [{ id: 'note-1', internal: false, ...noteProps }],
    ...discussionProps,
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
      provide: merge({ store }, defaultProvide, provide),
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
    defaultProps = {
      requestLastNoteEditing: jest.fn(),
    };
    store = {
      replyToDiscussion: jest.fn().mockResolvedValue(),
    };
  });

  it('renders discussion notes', () => {
    createComponent();
    expect(wrapper.findComponent(DiscussionNotes).props('notes')).toStrictEqual(
      createDiscussion().notes,
    );
  });

  describe('discussion navigation data attributes', () => {
    it('sets data-discussion-resolvable when discussion is resolvable', () => {
      createComponent({
        props: { discussion: createDiscussion({ resolvable: true, resolved: false }) },
      });
      expect(wrapper.attributes('data-discussion-resolvable')).toBe('true');
      expect(wrapper.attributes('data-discussion-resolved')).toBeUndefined();
    });

    it('sets data-discussion-resolved when discussion is resolved', () => {
      createComponent({
        props: { discussion: createDiscussion({ resolvable: true, resolved: true }) },
      });
      expect(wrapper.attributes('data-discussion-resolvable')).toBe('true');
      expect(wrapper.attributes('data-discussion-resolved')).toBe('true');
    });

    it('does not set data-discussion-resolvable when discussion is not resolvable', () => {
      createComponent({
        props: { discussion: createDiscussion({ resolvable: false }) },
      });
      expect(wrapper.attributes('data-discussion-resolvable')).toBeUndefined();
    });
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

  it('hides reply wrapper for individual notes', () => {
    createComponent({ props: { discussion: createDiscussion({ individual_note: true }) } });
    expect(wrapper.find('[data-testid="reply-wrapper"]').exists()).toBe(false);
  });

  it('starts replying', async () => {
    createComponent();
    await wrapper.findComponent(DiscussionReplyPlaceholder).vm.$emit('focus');
    await nextTick();
    expect(wrapper.emitted('startReplying')).toStrictEqual([[]]);
  });

  it('shows note form when reply mode is on', () => {
    createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(false);
  });

  it('stops replying', async () => {
    createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });
    await wrapper.findComponent(NoteForm).vm.$emit('cancel', false, false);
    await nextTick();
    expect(confirmAction).not.toHaveBeenCalled();
    expect(wrapper.emitted('stopReplying')).toStrictEqual([[]]);
  });

  it('shows confirmation when form is dirty', async () => {
    confirmAction.mockResolvedValue(true);
    createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });
    await wrapper.findComponent(NoteForm).vm.$emit('cancel', true, true);
    expect(confirmAction).toHaveBeenCalled();
    await waitForPromises();
    await nextTick();
    expect(wrapper.emitted('stopReplying')).toStrictEqual([[]]);
  });

  it('does not hide form when confirmation is declined', async () => {
    confirmAction.mockResolvedValue(false);
    createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });
    await wrapper.findComponent(NoteForm).vm.$emit('cancel', true, true);
    await nextTick();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
    expect(wrapper.findComponent(DiscussionReplyPlaceholder).exists()).toBe(false);
    expect(wrapper.emitted('stopReplying')).toBe(undefined);
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

  it('propagates noteEdited event', () => {
    const note = {};
    const value = 'edit';
    createComponent();
    wrapper.findComponent(DiscussionNotes).vm.$emit('noteEdited', { note, value });
    expect(wrapper.emitted('noteEdited')).toStrictEqual([[{ note, value }]]);
  });

  describe('timelineLayout prop', () => {
    it('passes timelineLayout to DiscussionNotes', () => {
      createComponent({ props: { timelineLayout: true } });
      expect(wrapper.findComponent(DiscussionNotes).props('timelineLayout')).toBe(true);
    });

    it('defaults timelineLayout to false', () => {
      createComponent();
      expect(wrapper.findComponent(DiscussionNotes).props('timelineLayout')).toBe(false);
    });
  });

  describe('isLastDiscussion prop', () => {
    it('passes isLastDiscussion to DiscussionNotes', () => {
      createComponent({ props: { isLastDiscussion: true } });
      expect(wrapper.findComponent(DiscussionNotes).props('isLastDiscussion')).toBe(true);
    });

    it('defaults isLastDiscussion to false', () => {
      createComponent();
      expect(wrapper.findComponent(DiscussionNotes).props('isLastDiscussion')).toBe(false);
    });
  });

  describe('when saving reply', () => {
    beforeEach(() => {
      detectAndConfirmSensitiveTokens.mockResolvedValue(true);
    });

    it('calls store.replyToDiscussion and closes form', async () => {
      const discussion = createDiscussion({ isReplying: true });
      createComponent({ props: { discussion } });
      await wrapper.findComponent(NoteForm).props('saveNote')('test note');
      expect(store.replyToDiscussion).toHaveBeenCalledWith(discussion, 'test note');
      expect(wrapper.emitted('stopReplying')).toStrictEqual([[]]);
    });

    it('does not save when sensitive token detection is declined', async () => {
      detectAndConfirmSensitiveTokens.mockResolvedValue(false);
      createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });
      await wrapper.findComponent(NoteForm).props('saveNote')('test note');
      expect(store.replyToDiscussion).not.toHaveBeenCalled();
    });

    it('shows alert when save fails', async () => {
      store.replyToDiscussion.mockRejectedValue({
        response: { data: {}, status: 500 },
      });
      createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });

      await wrapper.findComponent(NoteForm).props('saveNote')('test note');

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK,
        }),
      );
      expect(wrapper.emitted('stopReplying')).toBe(undefined);
    });

    it('shows generic alert when save fails without a response', async () => {
      store.replyToDiscussion.mockRejectedValue(new Error('fail'));
      createComponent({ props: { discussion: createDiscussion({ isReplying: true }) } });

      await wrapper.findComponent(NoteForm).props('saveNote')('test note');

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK,
        }),
      );
      expect(wrapper.emitted('stopReplying')).toBe(undefined);
    });
  });

  it('passes data to form', () => {
    const requestLastNoteEditing = jest.fn();
    const discussion = createDiscussion({ isReplying: true });
    createComponent({ props: { discussion, requestLastNoteEditing } });
    const props = wrapper.findComponent(NoteForm).props();
    props.requestLastNoteEditing();
    expect(props.saveButtonTitle).toBe('Reply');
    expect(props.autosaveKey).toBeDefined();
    expect(props.internal).toBe(false);
    expect(requestLastNoteEditing).toHaveBeenCalledWith(discussion);
  });

  it('passes correct saveButtonTitle for internal discussion', () => {
    createComponent({
      props: { discussion: { ...createDiscussion({ isReplying: true }), internal: true } },
    });
    const props = wrapper.findComponent(NoteForm).props();
    expect(props.saveButtonTitle).toBe('Reply internally');
    expect(props.internal).toBe(true);
  });

  describe('draft review support', () => {
    it('hides reply wrapper for draft discussions', () => {
      createComponent({
        props: { discussion: createDiscussion({ isDraft: true }) },
      });
      expect(wrapper.find('[data-testid="reply-wrapper"]').exists()).toBe(false);
    });

    describe('saveDraft', () => {
      beforeEach(() => {
        detectAndConfirmSensitiveTokens.mockResolvedValue(true);
        store.addDraftToDiscussion = jest.fn().mockResolvedValue();
      });

      it('passes saveDraft to NoteForm when canStartReview', () => {
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        expect(wrapper.findComponent(NoteForm).props('saveDraft')).toEqual(expect.any(Function));
      });

      it('does not pass saveDraft when store lacks addDraftToDiscussion', () => {
        delete store.addDraftToDiscussion;
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        expect(wrapper.findComponent(NoteForm).props('saveDraft')).toBeNull();
      });

      it('does not pass saveDraft when discussion already has a draft reply', () => {
        const discussion = createDiscussion({ isReplying: true });
        discussion.notes.push({ id: 'draft-1', isDraft: true });
        createComponent({ props: { discussion } });
        expect(wrapper.findComponent(NoteForm).props('saveDraft')).toBeNull();
      });

      it('passes hasDrafts to NoteForm', () => {
        store.hasDrafts = true;
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        expect(wrapper.findComponent(NoteForm).props('hasDrafts')).toBe(true);
      });

      it('calls store.addDraftToDiscussion and closes form', async () => {
        const discussion = createDiscussion({ isReplying: true });
        createComponent({ props: { discussion } });
        await wrapper.findComponent(NoteForm).props('saveDraft')('draft text');
        expect(store.addDraftToDiscussion).toHaveBeenCalledWith(discussion, 'draft text');
        expect(wrapper.emitted('stopReplying')).toStrictEqual([[]]);
      });

      it('does not save draft when sensitive token detection is declined', async () => {
        detectAndConfirmSensitiveTokens.mockResolvedValue(false);
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        await wrapper.findComponent(NoteForm).props('saveDraft')('draft text');
        expect(store.addDraftToDiscussion).not.toHaveBeenCalled();
      });

      it('shows alert when draft save fails', async () => {
        store.addDraftToDiscussion.mockRejectedValue({
          response: { data: {}, status: 500 },
        });
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        await wrapper.findComponent(NoteForm).props('saveDraft')('draft text');
        expect(createAlert).toHaveBeenCalled();
        expect(wrapper.emitted('stopReplying')).toBe(undefined);
      });

      it('shows generic alert when draft save fails without a response', async () => {
        store.addDraftToDiscussion.mockRejectedValue(new Error('fail'));
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        await wrapper.findComponent(NoteForm).props('saveDraft')('draft text');
        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK,
          }),
        );
        expect(wrapper.emitted('stopReplying')).toBe(undefined);
      });

      it('cancels form when empty text is passed', async () => {
        createComponent({
          props: { discussion: createDiscussion({ isReplying: true }) },
        });
        await wrapper.findComponent(NoteForm).props('saveDraft')('');
        expect(store.addDraftToDiscussion).not.toHaveBeenCalled();
      });
    });
  });

  describe('resolve button', () => {
    const resolvableNote = {
      id: 'note-1',
      resolvable: true,
      current_user: { can_resolve_discussion: true },
    };

    it('renders resolve button for resolvable discussions', () => {
      createComponent({
        props: {
          discussion: createDiscussion({ resolvable: true, resolved: false }, resolvableNote),
          toggleResolveNote: jest.fn(),
        },
      });
      const button = wrapper.findComponent(ResolveDiscussionButton);
      expect(button.exists()).toBe(true);
      expect(button.props('buttonTitle')).toBe('Resolve thread');
    });

    it('shows unresolve title when discussion is resolved', () => {
      createComponent({
        props: {
          discussion: createDiscussion({ resolvable: true, resolved: true }, resolvableNote),
          toggleResolveNote: jest.fn(),
        },
      });
      expect(wrapper.findComponent(ResolveDiscussionButton).props('buttonTitle')).toBe(
        'Reopen thread',
      );
    });

    it('does not render resolve button for non-resolvable discussions', () => {
      createComponent({
        props: {
          discussion: createDiscussion({ resolvable: false }),
          toggleResolveNote: jest.fn(),
        },
      });
      expect(wrapper.findComponent(ResolveDiscussionButton).exists()).toBe(false);
    });

    it('does not render resolve button when user cannot resolve', () => {
      createComponent({
        props: {
          discussion: createDiscussion(
            { resolvable: true },
            { id: 'note-1', resolvable: true, current_user: { can_resolve_discussion: false } },
          ),
          toggleResolveNote: jest.fn(),
        },
      });
      expect(wrapper.findComponent(ResolveDiscussionButton).exists()).toBe(false);
    });

    it('does not render resolve button when toggleResolveNote is not provided', () => {
      createComponent({
        props: {
          discussion: createDiscussion({ resolvable: true }, resolvableNote),
        },
      });
      expect(wrapper.findComponent(ResolveDiscussionButton).exists()).toBe(false);
    });

    it('calls toggleResolveNote when resolve button is clicked', async () => {
      const toggleResolveNote = jest.fn().mockResolvedValue();
      const discussion = createDiscussion({ resolvable: true, resolved: false }, resolvableNote);
      createComponent({
        props: { discussion, toggleResolveNote },
      });
      await wrapper.findComponent(ResolveDiscussionButton).vm.$emit('on-click');
      expect(toggleResolveNote).toHaveBeenCalledWith(discussion);
    });

    it('shows alert when resolving fails', async () => {
      const toggleResolveNote = jest.fn().mockRejectedValue(new Error('fail'));
      const discussion = createDiscussion({ resolvable: true, resolved: false }, resolvableNote);
      createComponent({
        props: { discussion, toggleResolveNote },
      });
      await wrapper.findComponent(ResolveDiscussionButton).vm.$emit('on-click');
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Something went wrong while resolving this discussion. Please try again.',
        }),
      );
    });
  });
});
