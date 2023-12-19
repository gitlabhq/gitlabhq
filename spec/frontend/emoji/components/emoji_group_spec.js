import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { GlButton } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EmojiGroup from '~/emoji/components/emoji_group.vue';

Vue.config.ignoredElements = ['gl-emoji'];

let wrapper;
function factory(propsData = {}) {
  wrapper = extendedWrapper(
    shallowMount(EmojiGroup, {
      propsData,
      stubs: {
        GlButton,
      },
    }),
  );
}

describe('Emoji group component', () => {
  it('does not render any buttons', () => {
    factory({
      emojis: [],
      renderGroup: false,
    });

    expect(wrapper.findByTestId('emoji-button').exists()).toBe(false);
  });

  it('renders emojis', () => {
    factory({
      emojis: ['thumbsup', 'thumbsdown'],
      renderGroup: true,
    });

    expect(wrapper.findAllByTestId('emoji-button').exists()).toBe(true);
    expect(wrapper.findAllByTestId('emoji-button').length).toBe(2);
  });

  it('emits emoji-click', () => {
    factory({
      emojis: ['thumbsup', 'thumbsdown'],
      renderGroup: true,
    });

    wrapper.findComponent(GlButton).vm.$emit('click');

    expect(wrapper.emitted('emoji-click')).toStrictEqual([['thumbsup']]);
  });
});
