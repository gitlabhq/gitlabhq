import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TimelineEventButton from '~/notes/components/note_actions/timeline_event_button.vue';

const emitData = {
  noteId: '1',
  addError: 'Error promoting the note to timeline event: %{error}',
  addGenericError: 'Something went wrong while promoting the note to timeline event.',
};

describe('NoteTimelineEventButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(TimelineEventButton, {
      propsData: {
        noteId: '1',
        isPromotionInProgress: true,
      },
    });
  });

  const findTimelineButton = () => wrapper.findComponent(GlButton);

  it('emits click-promote-comment-to-event', () => {
    findTimelineButton().vm.$emit('click');

    expect(wrapper.emitted('click-promote-comment-to-event')).toEqual([[emitData]]);
    expect(findTimelineButton().props('disabled')).toEqual(true);
  });
});
