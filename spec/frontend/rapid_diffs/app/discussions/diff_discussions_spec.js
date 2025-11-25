import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NoteableDiscussion from '~/rapid_diffs/app/discussions/noteable_discussion.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

describe('DiffDiscussions', () => {
  let pinia;
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffDiscussions, {
      pinia,
      propsData: props,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia();
  });

  it('renders noteable discussions', () => {
    const discussion1 = { id: '1' };
    const discussion2 = { id: '2' };
    createComponent({ discussions: [discussion1, discussion2] });
    expect(
      wrapper
        .findAllComponents(NoteableDiscussion)
        .wrappers.map((component) => component.props('discussion')),
    ).toStrictEqual([discussion1, discussion2]);
  });

  it('provides data', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    const props = wrapper.findComponent(NoteableDiscussion).props();
    props.requestLastNoteEditing();
    expect(props.discussion).toBe(discussion);
    expect(useDiffDiscussions().requestLastNoteEditing).toHaveBeenCalled();
  });

  it('handles startReplying event', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('startReplying');
    expect(useDiffDiscussions().startReplying).toHaveBeenCalledWith(discussion);
  });

  it('handles stopReplying event', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('stopReplying');
    expect(useDiffDiscussions().stopReplying).toHaveBeenCalledWith(discussion);
  });

  it('toggles replies', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('toggleDiscussionReplies');
    expect(useDiffDiscussions().toggleDiscussionReplies).toHaveBeenCalledWith(discussion);
  });

  it('handles replyAdded event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('replyAdded', note);
    expect(useDiffDiscussions().addNote).toHaveBeenCalledWith(note);
  });

  it('handles noteUpdated event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('noteUpdated', note);
    expect(useDiffDiscussions().updateNote).toHaveBeenCalledWith(note);
  });

  it('handles noteDeleted event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('noteDeleted', note);
    expect(useDiffDiscussions().deleteNote).toHaveBeenCalledWith(note);
  });

  it('handles startEditing event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('startEditing', note);
    expect(useDiffDiscussions().setEditingMode).toHaveBeenCalledWith(note, true);
  });

  it('handles cancelEditing event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('cancelEditing', note);
    expect(useDiffDiscussions().setEditingMode).toHaveBeenCalledWith(note, false);
  });

  it('handles toggleAward event', () => {
    const note = { id: '1' };
    const award = 'smile';
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('toggleAward', { note, award });
    expect(useDiffDiscussions().toggleAward).toHaveBeenCalledWith({ note, award });
  });

  it('handles noteEdited event', () => {
    const note = { id: '1' };
    const value = 'edit';
    createComponent({ discussions: [{ id: '1', notes: [note] }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('noteEdited', { note, value });
    expect(useDiffDiscussions().editNote).toHaveBeenCalledWith({ note, value });
  });
});
