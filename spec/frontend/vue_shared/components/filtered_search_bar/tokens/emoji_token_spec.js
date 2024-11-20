import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { EMOJI_THUMBS_UP } from '~/emoji/constants';

import {
  OPTION_NONE,
  OPTION_ANY,
  OPTIONS_NONE_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockReactionEmojiToken, mockEmojis } from '../mock_data';

jest.mock('~/alert');
const GlEmoji = { template: '<img/>' };
const defaultStubs = {
  Portal: true,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
  GlEmoji,
};

function createComponent(options = {}) {
  const {
    config = mockReactionEmojiToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
  } = options;
  return mount(EmojiToken, {
    propsData: {
      config,
      value,
      active,
      cursorPosition: 'start',
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: () => 'custom-class',
      termsAsTokens: () => false,
    },
    stubs,
  });
}

describe('EmojiToken', () => {
  let mock;
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const triggerFetchEmojis = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('methods', () => {
    describe('fetchEmojis', () => {
      it('sets loading state', async () => {
        wrapper = createComponent({
          config: {
            fetchEmojis: jest.fn().mockResolvedValue(new Promise(() => {})),
          },
        });
        await nextTick();

        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when request is successful', () => {
        const searchTerm = 'foo';

        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchEmojis: jest.fn().mockResolvedValue({ data: mockEmojis }),
            },
          });
          return triggerFetchEmojis(searchTerm);
        });

        it('calls `config.fetchEmojis` with provided searchTerm param', () => {
          expect(findBaseToken().props('config').fetchEmojis).toHaveBeenCalledWith(searchTerm);
        });

        it('sets response to `emojis`', () => {
          expect(findBaseToken().props('suggestions')).toEqual(mockEmojis);
        });
      });

      describe('when request fails', () => {
        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchEmojis: jest.fn().mockRejectedValue({}),
            },
          });
          return triggerFetchEmojis();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching emoji.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultEmojis = OPTIONS_NONE_ANY;

    beforeEach(() => {
      wrapper = createComponent({
        value: { data: `"${mockEmojis[0].name}"` },
        config: {
          initialEmojis: mockEmojis,
        },
      });
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.findComponent(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // My Reaction, =, "thumbsup"
      expect(tokenSegments.at(2).findComponent(GlEmoji).attributes('data-name')).toEqual(
        EMOJI_THUMBS_UP,
      );
    });

    it('renders provided defaultEmojis as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockReactionEmojiToken, defaultEmojis },
        stubs: { Portal: true, GlEmoji },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(defaultEmojis.length);
      defaultEmojis.forEach((emoji, index) => {
        expect(suggestions.at(index).text()).toBe(emoji.text);
      });
    });

    it('does not render divider when no defaultEmojis', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockReactionEmojiToken, defaultEmojis: [] },
        stubs: { Portal: true, GlEmoji },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `OPTION_NONE` and `OPTION_ANY` as default suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockReactionEmojiToken },
        stubs: { Portal: true, GlEmoji },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(2);
      expect(suggestions.at(0).text()).toBe(OPTION_NONE.text);
      expect(suggestions.at(1).text()).toBe(OPTION_ANY.text);
    });
  });
});
