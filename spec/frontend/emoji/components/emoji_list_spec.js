import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EmojiList from '~/emoji/components/emoji_list.vue';

jest.mock('~/emoji', () => ({
  initEmojiMap: jest.fn(() => Promise.resolve()),
  searchEmoji: jest.fn((search) => [{ emoji: { name: search } }]),
  getEmojiCategoryMap: jest.fn(() =>
    Promise.resolve({
      activity: ['thumbsup', 'thumbsdown'],
    }),
  ),
}));

let wrapper;
async function factory(render, propsData = { searchValue: '' }) {
  wrapper = extendedWrapper(
    shallowMount(EmojiList, {
      propsData,
      scopedSlots: {
        default: '<div data-testid="default-slot">{{props.filteredCategories}}</div>',
      },
    }),
  );

  // Wait for categories to be set
  await nextTick();

  if (render) {
    wrapper.setData({ render: true });

    // Wait for component to render
    await nextTick();
  }
}

const findDefaultSlot = () => wrapper.findByTestId('default-slot');

describe('Emoji list component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('does not render until render is set', async () => {
    await factory(false);

    expect(findDefaultSlot().exists()).toBe(false);
  });

  it('renders with none filtered list', async () => {
    await factory(true);

    expect(JSON.parse(findDefaultSlot().text())).toEqual({
      activity: {
        emojis: [['thumbsup', 'thumbsdown']],
        height: expect.any(Number),
        top: expect.any(Number),
      },
    });
  });

  it('renders filtered list of emojis', async () => {
    await factory(true, { searchValue: 'smile' });

    expect(JSON.parse(findDefaultSlot().text())).toEqual({
      search: {
        emojis: [['smile']],
        height: expect.any(Number),
      },
    });
  });
});
