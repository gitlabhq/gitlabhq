import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Category from '~/emoji/components/category.vue';
import EmojiGroup from '~/emoji/components/emoji_group.vue';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

let wrapper;
function factory(propsData = {}) {
  wrapper = shallowMount(Category, { propsData });
}

const triggerGlIntersectionObserver = () => {
  wrapper.findComponent(GlIntersectionObserver).vm.$emit('appear');
  return nextTick();
};

describe('Emoji category component', () => {
  beforeEach(() => {
    factory({
      category: 'Activity',
      emojis: [[EMOJI_THUMBS_UP], [EMOJI_THUMBS_DOWN]],
    });
  });

  it('renders emoji groups', () => {
    expect(wrapper.findAllComponents(EmojiGroup).length).toBe(2);
  });

  it('renders group', async () => {
    await triggerGlIntersectionObserver();

    expect(wrapper.findComponent(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('renders group on appear', async () => {
    await triggerGlIntersectionObserver();

    expect(wrapper.findComponent(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('emits appear event on appear', async () => {
    await triggerGlIntersectionObserver();

    expect(wrapper.emitted().appear[0]).toEqual(['Activity']);
  });
});
