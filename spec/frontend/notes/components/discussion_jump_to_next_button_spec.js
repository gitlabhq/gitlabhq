import jumpToNextDiscussionButton from '~/notes/components/discussion_jump_to_next_button.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();

describe('jumpToNextDiscussionButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(jumpToNextDiscussionButton, {
      localVue,
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('emits onClick event on button click', done => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    localVue.nextTick(() => {
      expect(wrapper.emitted()).toEqual({
        onClick: [[]],
      });

      done();
    });
  });
});
