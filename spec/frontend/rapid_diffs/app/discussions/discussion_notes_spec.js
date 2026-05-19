import { merge } from 'lodash-es';
import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DiscussionNotes from '~/rapid_diffs/app/discussions/discussion_notes.vue';
import DraftNote from '~/rapid_diffs/app/discussions/draft_note.vue';
import NoteableNote from '~/rapid_diffs/app/discussions/noteable_note.vue';
import SystemNote from '~/rapid_diffs/app/discussions/system_note.vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';

describe('DiscussionNotes', () => {
  let wrapper;

  const defaultProvisions = {
    userPermissions: {
      can_create_note: false,
    },
  };

  const createComponent = (propsData = {}, { provide = {}, scopedSlots = {} } = {}) => {
    wrapper = shallowMount(DiscussionNotes, {
      propsData,
      provide: merge(defaultProvisions, provide),
      scopedSlots,
      stubs: { GlSprintf },
    });
  };

  it('shows replies toggle', () => {
    const reply = { id: 'bar' };
    createComponent({ notes: [{ id: 'foo' }, reply] });
    const repliesComponent = wrapper.findComponent(ToggleRepliesWidget);
    expect(repliesComponent.props('replies')).toStrictEqual([reply]);
    expect(repliesComponent.props('collapsed')).toBe(false);
  });

  it('propagates toggle event', () => {
    createComponent({ notes: [{ id: 'foo' }, { id: 'bar' }] });
    wrapper.findComponent(ToggleRepliesWidget).vm.$emit('toggle');
    expect(wrapper.emitted('toggleDiscussionReplies')).toStrictEqual([[]]);
  });

  it('provides footer slot when expanded', () => {
    const footer = jest.fn();
    createComponent(
      { notes: [{ id: 'foo' }, { id: 'bar' }], expanded: true },
      { scopedSlots: { footer } },
    );
    expect(footer).toHaveBeenCalledWith({ hasReplies: true });
  });

  describe('noteable notes', () => {
    describe('first note', () => {
      it('renders as first note', () => {
        const note = { id: 'foo' };
        createComponent({ notes: [note] });
        const noteComponent = wrapper.findComponent(NoteableNote);
        expect(noteComponent.props('note')).toBe(note);
        expect(noteComponent.props('showReplyButton')).toBe(
          defaultProvisions.userPermissions.can_create_note,
        );
      });
    });

    describe('draft replies', () => {
      it('renders draft replies via DraftNote component', () => {
        const draftReply = { id: 'draft-1', isDraft: true };
        createComponent(
          { notes: [{ id: 'first' }, draftReply] },
          { provide: { store: {}, endpoints: {}, userPermissions: { can_create_note: true } } },
        );
        expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
        expect(wrapper.findComponent(DraftNote).props('draft')).toBe(draftReply);
      });

      it('excludes draft replies from toggle replies widget', () => {
        const draftReply = { id: 'draft-1', isDraft: true };
        createComponent(
          { notes: [{ id: 'first' }, { id: 'regular' }, draftReply] },
          { provide: { userPermissions: { can_create_note: true } } },
        );
        const replies = wrapper.findComponent(ToggleRepliesWidget).props('replies');
        expect(replies).toHaveLength(1);
        expect(replies[0].id).toBe('regular');
      });

      it('shows draft replies even when collapsed', () => {
        const draftReply = { id: 'draft-1', isDraft: true };
        createComponent(
          { notes: [{ id: 'first' }, { id: 'regular' }, draftReply], expanded: false },
          { provide: { store: {}, endpoints: {}, userPermissions: { can_create_note: true } } },
        );
        expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
      });

      it('propagates startReplying event', () => {
        const note = { id: 'foo' };
        createComponent({ notes: [note] });
        wrapper.findComponent(NoteableNote).vm.$emit('startReplying');
        expect(wrapper.emitted('startReplying')).toStrictEqual([[]]);
      });

      it('propagates noteEdited event', () => {
        const value = 'smile';
        const note = { id: 'foo' };
        createComponent({ notes: [note] });
        wrapper.findComponent(NoteableNote).vm.$emit('noteEdited', value);
        expect(wrapper.emitted('noteEdited')).toStrictEqual([[{ note, value }]]);
      });
    });

    describe('all notes', () => {
      const notes = [{ id: 'first' }, { id: 'second' }];

      describe.each(notes)('for %s note', (note) => {
        const findNoteableNote = () => {
          return wrapper
            .findAllComponents(NoteableNote)
            .filter((component) => component.props('note') === note)
            .at(0);
        };

        it('renders note', () => {
          createComponent({ notes });
          expect(findNoteableNote().exists()).toBe(true);
        });

        it.each(['startEditing', 'cancelEditing'])('propagates %s event', (event) => {
          createComponent({ notes });
          findNoteableNote().vm.$emit(event, note);
          expect(wrapper.emitted(event)).toStrictEqual([[note]]);
        });

        it('propagates noteEdited event', () => {
          const value = 'smile';
          createComponent({ notes });
          findNoteableNote().vm.$emit('noteEdited', value);
          expect(wrapper.emitted('noteEdited')).toStrictEqual([[{ note, value }]]);
        });
      });
    });
  });

  describe('system notes', () => {
    it('renders as first note', () => {
      const note = { id: 'foo', system: true };
      createComponent({ notes: [note] });
      expect(wrapper.findComponent(SystemNote).props('note')).toBe(note);
    });

    it('renders as reply', () => {
      const reply = { id: 'bar', system: true };
      createComponent({ notes: [{ id: 'foo' }, reply] });
      expect(wrapper.findComponent(SystemNote).props('note')).toBe(reply);
    });

    it('passes isLastDiscussion to system note', () => {
      const note = { id: 'foo', system: true };
      createComponent({ notes: [note], isLastDiscussion: true });
      expect(wrapper.findComponent(SystemNote).props('isLastDiscussion')).toBe(true);
    });
  });

  describe('timelineLayout prop', () => {
    it('passes timelineLayout to NoteableNote', () => {
      const note = { id: 'foo' };
      createComponent({ notes: [note], timelineLayout: true });
      expect(wrapper.findComponent(NoteableNote).props('timelineLayout')).toBe(true);
    });

    it('defaults timelineLayout to false', () => {
      const note = { id: 'foo' };
      createComponent({ notes: [note] });
      expect(wrapper.findComponent(NoteableNote).props('timelineLayout')).toBe(false);
    });
  });

  describe('isLastDiscussion prop', () => {
    it('passes isLastDiscussion to NoteableNote', () => {
      const note = { id: 'foo' };
      createComponent({ notes: [note], isLastDiscussion: true });
      expect(wrapper.findComponent(NoteableNote).props('isLastDiscussion')).toBe(true);
    });

    it('defaults isLastDiscussion to false', () => {
      const note = { id: 'foo' };
      createComponent({ notes: [note] });
      expect(wrapper.findComponent(NoteableNote).props('isLastDiscussion')).toBe(false);
    });
  });

  describe('multiline comment headline', () => {
    const multiLineRange = {
      start: { old_line: 5, new_line: 5, type: null },
      end: { old_line: 8, new_line: 8, type: null },
    };

    const singleLineRange = {
      start: { old_line: 5, new_line: 5, type: null },
      end: { old_line: 5, new_line: 5, type: null },
    };

    it('does not render headline when note has no position', () => {
      createComponent({ notes: [{ id: 'foo' }] });
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('does not render headline when note has no line range', () => {
      createComponent({ notes: [{ id: 'foo', position: {} }] });
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('does not render headline for a single-line comment', () => {
      createComponent({
        notes: [{ id: 'foo', position: { line_range: singleLineRange } }],
      });
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('renders headline for a multi-line comment', () => {
      createComponent({
        notes: [{ id: 'foo', position: { line_range: multiLineRange } }],
      });
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
    });

    it('renders the start and end line numbers', () => {
      createComponent({ notes: [{ id: 'foo', position: { line_range: multiLineRange } }] });

      expect(wrapper.text()).toContain('Comment on lines 5 to 8');
    });
  });
});
