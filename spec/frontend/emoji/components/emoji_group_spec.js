import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EmojiGroup from '~/emoji/components/emoji_group.vue';

Vue.config.ignoredElements = ['gl-emoji'];

let wrapper;
function factory(propsData = {}) {
  wrapper = extendedWrapper(
    shallowMount(EmojiGroup, {
      propsData,
    }),
  );
}

describe('Emoji group component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('does not render any buttons', () => {
    factory({
      emojis: [],
      renderGroup: false,
      clickEmoji: jest.fn(),
    });

    expect(wrapper.findByTestId('emoji-button').exists()).toBe(false);
  });

  it('renders emojis', () => {
    factory({
      emojis: ['thumbsup', 'thumbsdown'],
      renderGroup: true,
      clickEmoji: jest.fn(),
    });

    expect(wrapper.findAllByTestId('emoji-button').exists()).toBe(true);
    expect(wrapper.findAllByTestId('emoji-button').length).toBe(2);
  });

  it('calls clickEmoji', () => {
    const clickEmoji = jest.fn();

    factory({
      emojis: ['thumbsup', 'thumbsdown'],
      renderGroup: true,
      clickEmoji,
    });

    wrapper.findByTestId('emoji-button').trigger('click');

    expect(clickEmoji).toHaveBeenCalledWith('thumbsup');
  });
});
