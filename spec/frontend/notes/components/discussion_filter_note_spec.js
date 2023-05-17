import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DiscussionFilterNote from '~/notes/components/discussion_filter_note.vue';
import eventHub from '~/notes/event_hub';

describe('DiscussionFilterNote component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DiscussionFilterNote, {
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('timelineContent renders a string containing instruction for switching feed type', () => {
    expect(wrapper.find('[data-testid="discussion-filter-timeline-content"]').html()).toBe(
      '<div data-testid="discussion-filter-timeline-content">You\'re only seeing <b>other activity</b> in the feed. To add a comment, switch to one of the following options.</div>',
    );
  });

  it('emits `dropdownSelect` event with 0 parameter on clicking Show all activity button', () => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    wrapper.findAllComponents(GlButton).at(0).vm.$emit('click');

    expect(eventHub.$emit).toHaveBeenCalledWith('dropdownSelect', 0);
  });

  it('emits `dropdownSelect` event with 1 parameter on clicking Show comments only button', () => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    wrapper.findAllComponents(GlButton).at(1).vm.$emit('click');

    expect(eventHub.$emit).toHaveBeenCalledWith('dropdownSelect', 1);
  });
});
