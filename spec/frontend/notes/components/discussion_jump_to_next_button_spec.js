import { shallowMount } from '@vue/test-utils';
import JumpToNextDiscussionButton from '~/notes/components/discussion_jump_to_next_button.vue';

describe('JumpToNextDiscussionButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(JumpToNextDiscussionButton, {
      attachToDocument: true,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    expect(wrapper.vm.$el).toMatchSnapshot();
  });

  it('emits onClick event on button click', () => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().onClick).toBeTruthy();
      expect(wrapper.emitted().onClick.length).toBe(1);
    });
  });
});
