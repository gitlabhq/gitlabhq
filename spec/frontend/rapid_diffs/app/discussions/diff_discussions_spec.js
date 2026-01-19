import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NoteableDiscussion from '~/rapid_diffs/app/discussions/noteable_discussion.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
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

  it('handles discussionUpdated event', () => {
    const discussion = { id: '1' };
    const updatedDiscussion = { id: '1', notes: [{ id: 'new-note' }] };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('discussionUpdated', updatedDiscussion);
    expect(useDiffDiscussions().replaceDiscussion).toHaveBeenCalledWith(
      discussion,
      updatedDiscussion,
    );
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

  describe('timelineLayout prop', () => {
    it('passes timelineLayout to NoteableDiscussion', () => {
      createComponent({ discussions: [{ id: '1' }], timelineLayout: true });
      expect(wrapper.findComponent(NoteableDiscussion).props('timelineLayout')).toBe(true);
    });

    it('defaults timelineLayout to false', () => {
      createComponent({ discussions: [{ id: '1' }] });
      expect(wrapper.findComponent(NoteableDiscussion).props('timelineLayout')).toBe(false);
    });
  });

  describe('isLastDiscussion prop', () => {
    it('passes isLastDiscussion as true for the last discussion', () => {
      createComponent({ discussions: [{ id: '1' }, { id: '2' }] });
      const discussions = wrapper.findAllComponents(NoteableDiscussion);
      expect(discussions.at(0).props('isLastDiscussion')).toBe(false);
      expect(discussions.at(1).props('isLastDiscussion')).toBe(true);
    });

    it('passes isLastDiscussion as true for single discussion', () => {
      createComponent({ discussions: [{ id: '1' }] });
      expect(wrapper.findComponent(NoteableDiscussion).props('isLastDiscussion')).toBe(true);
    });
  });

  it('shows counter badge', () => {
    createComponent({ discussions: [{ id: '1' }], counterBadgeVisible: true });
    expect(wrapper.findComponent(DesignNotePin).exists()).toBe(true);
    expect(wrapper.findComponent(DesignNotePin).props()).toMatchObject({
      label: 1,
      size: 'sm',
      clickable: false,
    });
  });
});
