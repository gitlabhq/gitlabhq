import { shallowMount } from '@vue/test-utils';
import JumpToNextDiscussionButton from '~/notes/components/discussion_jump_to_next_button.vue';

describe('JumpToNextDiscussionButton', () => {
  let wrapper;
  const fromDiscussionId = 'abc123';

  beforeEach(() => {
    wrapper = shallowMount(JumpToNextDiscussionButton, {
      propsData: { fromDiscussionId },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    expect(wrapper.vm.$el).toMatchSnapshot();
  });

  it('calls jumpToNextRelativeDiscussion when clicked', () => {
    const jumpToNextRelativeDiscussion = jest.fn();
    wrapper.setMethods({ jumpToNextRelativeDiscussion });
    wrapper.find({ ref: 'button' }).trigger('click');
    expect(jumpToNextRelativeDiscussion).toHaveBeenCalledWith(fromDiscussionId);
  });
});
