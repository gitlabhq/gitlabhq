import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import DiscussionNotes from '~/rapid_diffs/app/discussions/discussion_notes.vue';
import NoteableNote from '~/rapid_diffs/app/discussions/noteable_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
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

  it('provides footer slot', () => {
    const footer = jest.fn();
    createComponent({ notes: [{ id: 'foo' }, { id: 'bar' }] }, { scopedSlots: { footer } });
    expect(footer).toHaveBeenCalledWith({ repliesVisible: true });
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

      it('propagates startReplying event', () => {
        const note = { id: 'foo' };
        createComponent({ notes: [note] });
        wrapper.findComponent(NoteableNote).vm.$emit('startReplying');
        expect(wrapper.emitted('startReplying')).toStrictEqual([[]]);
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

        it.each(['noteDeleted', 'startEditing', 'cancelEditing'])(
          'propagates %s event',
          (event) => {
            createComponent({ notes });
            findNoteableNote().vm.$emit(event, note);
            expect(wrapper.emitted(event)).toStrictEqual([[note]]);
          },
        );

        it('propagates noteUpdated event', () => {
          const updatedNote = {};
          createComponent({ notes });
          findNoteableNote().vm.$emit('noteUpdated', updatedNote);
          expect(wrapper.emitted('noteUpdated')).toStrictEqual([[updatedNote]]);
        });

        it('propagates award event', () => {
          const award = 'smile';
          createComponent({ notes });
          findNoteableNote().vm.$emit('award', award);
          expect(wrapper.emitted('award')).toStrictEqual([[{ note, award }]]);
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
  });
});
