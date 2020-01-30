import { shallowMount } from '@vue/test-utils';
import JumpToNextDiscussionButton from '~/notes/components/discussion_jump_to_next_button.vue';

describe('JumpToNextDiscussionButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(JumpToNextDiscussionButton);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    expect(wrapper.vm.$el).toMatchSnapshot();
  });
});
