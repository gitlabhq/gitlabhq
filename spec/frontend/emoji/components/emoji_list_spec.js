import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EmojiList from '~/emoji/components/emoji_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

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

function factory(propsData = { searchValue: '' }) {
  wrapper = extendedWrapper(
    shallowMount(EmojiList, {
      propsData,
      scopedSlots: {
        default: '<div data-testid="default-slot">{{props.filteredCategories}}</div>',
      },
    }),
  );
}

const findDefaultSlot = () => wrapper.findByTestId('default-slot');

describe('Emoji list component', () => {
  it('does not render until render is set', async () => {
    factory();

    expect(findDefaultSlot().exists()).toBe(false);
    await waitForPromises();
    expect(findDefaultSlot().exists()).toBe(true);
  });

  it('renders with none filtered list', async () => {
    factory();

    await waitForPromises();

    expect(JSON.parse(findDefaultSlot().text())).toEqual({
      activity: {
        emojis: [[EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN]],
        height: expect.any(Number),
        top: expect.any(Number),
      },
    });
  });

  it('renders filtered list of emojis', async () => {
    factory({ searchValue: 'smile' });

    await waitForPromises();

    expect(JSON.parse(findDefaultSlot().text())).toEqual({
      search: {
        emojis: [['smile']],
        height: expect.any(Number),
      },
    });
  });
});
