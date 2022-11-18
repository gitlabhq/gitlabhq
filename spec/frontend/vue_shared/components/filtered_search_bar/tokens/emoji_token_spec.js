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
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';

import {
  OPTION_NONE,
  OPTION_ANY,
  OPTIONS_NONE_ANY,
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
      cursorPosition: 'start',
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: () => 'custom-class',
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

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('fetchEmojis', () => {
      it('calls `config.fetchEmojis` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis');

        wrapper.vm.fetchEmojis('foo');

        expect(wrapper.vm.config.fetchEmojis).toHaveBeenCalledWith('foo');
      });

      it('sets response to `emojis` when request is successful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis').mockResolvedValue(mockEmojis);

        wrapper.vm.fetchEmojis('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.emojis).toEqual(mockEmojis);
        });
      });

      it('calls `createAlert` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis').mockRejectedValue({});

        wrapper.vm.fetchEmojis('foo');

        return waitForPromises().then(() => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching emojis.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchEmojis').mockRejectedValue({});

        wrapper.vm.fetchEmojis('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.loading).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultEmojis = OPTIONS_NONE_ANY;

    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: `"${mockEmojis[0].name}"` },
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        emojis: mockEmojis,
      });

      await nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.findComponent(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // My Reaction, =, "thumbsup"
      expect(tokenSegments.at(2).findComponent(GlEmoji).attributes('data-name')).toEqual(
        'thumbsup',
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
