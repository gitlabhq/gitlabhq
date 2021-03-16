import { GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Category from '~/emoji/components/category.vue';
import EmojiGroup from '~/emoji/components/emoji_group.vue';

let wrapper;
function factory(propsData = {}) {
  wrapper = shallowMount(Category, { propsData });
}

describe('Emoji category component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    factory({
      category: 'Activity',
      emojis: [['thumbsup'], ['thumbsdown']],
    });
  });

  it('renders emoji groups', () => {
    expect(wrapper.findAll(EmojiGroup).length).toBe(2);
  });

  it('renders group', async () => {
    await wrapper.setData({ renderGroup: true });

    expect(wrapper.find(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('renders group on appear', async () => {
    wrapper.find(GlIntersectionObserver).vm.$emit('appear');

    await nextTick();

    expect(wrapper.find(EmojiGroup).attributes('rendergroup')).toBe('true');
  });

  it('emits appear event on appear', async () => {
    wrapper.find(GlIntersectionObserver).vm.$emit('appear');

    await nextTick();

    expect(wrapper.emitted().appear[0]).toEqual(['Activity']);
  });
});
