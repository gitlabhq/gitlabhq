import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import {
  DEFAULT_LABEL_NONE,
  DEFAULT_LABEL_ANY,
  DEFAULT_NONE_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';

import { mockReactionEmojiToken, mockEmojis } from '../mock_data';

jest.mock('~/flash');
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
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: 'custom-class',
    },
    stubs,
  });
}

describe('EmojiToken', () => {
  let mock;
  let wrapper;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('computed', () => {
    beforeEach(async () => {
      wrapper = createComponent({ value: { data: mockEmojis[0].name } });

      wrapper.setData({
        emojis: mockEmojis,
      });

      await wrapper.vm.$nextTick();
    });

    describe('currentValue', () => {
      it('returns lowercase string for `value.data`', () => {
        expect(wrapper.vm.currentValue).toBe(mockEmojis[0].name);
      });
    });

    describe('activeEmoji', () => {
      it('returns object for currently present `value.data`', () => {
        expect(wrapper.vm.activeEmoji).toEqual(mockEmojis[0]);
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('fetchEmojiBySearchTerm', () => {
      it('calls `config.fetchEmojis` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis');

        wrapper.vm.fetchEmojiBySearchTerm('foo');

        expect(wrapper.vm.config.fetchEmojis).toHaveBeenCalledWith('foo');
      });

      it('sets response to `emojis` when request is successful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis').mockResolvedValue(mockEmojis);

        wrapper.vm.fetchEmojiBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.emojis).toEqual(mockEmojis);
        });
      });

      it('calls `createFlash` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis').mockRejectedValue({});

        wrapper.vm.fetchEmojiBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was a problem fetching emojis.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis').mockRejectedValue({});

        wrapper.vm.fetchEmojiBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.loading).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultEmojis = DEFAULT_NONE_ANY;

    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: `"${mockEmojis[0].name}"` },
      });

      wrapper.setData({
        emojis: mockEmojis,
      });

      await wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.find(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // My Reaction, =, "thumbsup"
      expect(tokenSegments.at(2).find(GlEmoji).attributes('data-name')).toEqual('thumbsup');
    });

    it('renders provided defaultEmojis as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockReactionEmojiToken, defaultEmojis },
        stubs: { Portal: true, GlEmoji },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

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
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.find(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `DEFAULT_LABEL_NONE` and `DEFAULT_LABEL_ANY` as default suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockReactionEmojiToken },
        stubs: { Portal: true, GlEmoji },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(2);
      expect(suggestions.at(0).text()).toBe(DEFAULT_LABEL_NONE.text);
      expect(suggestions.at(1).text()).toBe(DEFAULT_LABEL_ANY.text);
    });
  });
});
