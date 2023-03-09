import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';

describe('ReplyButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ReplyButton);
  });

  it('emits startReplying on click', () => {
    wrapper.findComponent(GlButton).vm.$emit('click');

    expect(wrapper.emitted('startReplying')).toEqual([[]]);
  });
});
