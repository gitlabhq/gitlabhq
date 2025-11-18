import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import DiscussionNotes from '~/rapid_diffs/app/discussions/discussion_notes.vue';
import NoteableNote from '~/notes/components/noteable_note.vue';
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
      createComponent({ notes: [{ id: 'foo' }] });
      wrapper.findComponent(NoteableNote).vm.$emit('startReplying');
      expect(wrapper.emitted('startReplying')).toStrictEqual([[]]);
    });

    it('propagates noteDeleted event', () => {
      const notes = { id: 'foo' };
      createComponent({ notes: [notes] });
      wrapper.findComponent(NoteableNote).vm.$emit('noteDeleted');
      expect(wrapper.emitted('noteDeleted')).toStrictEqual([[notes]]);
    });

    it('renders as reply', () => {
      const reply = { id: 'bar' };
      createComponent({ notes: [{ id: 'foo' }, reply] });
      expect(wrapper.findAllComponents(NoteableNote).at(1).props('note')).toBe(reply);
    });

    it('propagates noteDeleted event on reply', () => {
      const reply = { id: 'bar' };
      createComponent({ notes: [{ id: 'foo' }, reply] });
      wrapper.findAllComponents(NoteableNote).at(1).vm.$emit('noteDeleted');
      expect(wrapper.emitted('noteDeleted')).toStrictEqual([[reply]]);
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
