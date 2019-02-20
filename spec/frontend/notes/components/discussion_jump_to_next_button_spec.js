import jumpToNextDiscussionButton from '~/notes/components/discussion_jump_to_next_button.vue';
import { shallowMount } from '@vue/test-utils';

describe('jumpToNextDiscussionButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(jumpToNextDiscussionButton, {
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('emits onClick event on button click', () => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    expect(wrapper.emitted()).toEqual({
      onClick: [[]],
    });
  });
});
