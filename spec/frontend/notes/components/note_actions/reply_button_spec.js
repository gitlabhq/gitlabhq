import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

describe('ReplyButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ReplyButton);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('emits startReplying on click', () => {
    wrapper.find(GlButton).vm.$emit('click');

    expect(wrapper.emitted('startReplying')).toEqual([[]]);
  });
});
