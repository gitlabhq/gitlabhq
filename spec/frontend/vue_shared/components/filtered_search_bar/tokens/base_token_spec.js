import { GlFilteredSearchToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';

import { DEFAULT_LABELS } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  getRecentlyUsedSuggestions,
  setTokenValueToRecentlyUsed,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockLabelToken } from '../mock_data';

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils');

const mockStorageKey = 'recent-tokens-label_name';

const defaultStubs = {
  Portal: true,
  GlFilteredSearchToken: {
    template: `
      <div>
        <slot name="view-token"></slot>
        <slot name="view"></slot>
      </div>
    `,
  },
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

const defaultSlots = {
  'view-token': `
    <div class="js-view-token">${mockRegularLabel.title}</div>
  `,
  view: `
    <div class="js-view">${mockRegularLabel.title}</div>
  `,
};

const mockProps = {
  config: mockLabelToken,
  value: { data: '' },
  active: false,
  suggestions: [],
  suggestionsLoading: false,
  defaultSuggestions: DEFAULT_LABELS,
  recentSuggestionsStorageKey: mockStorageKey,
  fnCurrentTokenValue: jest.fn(),
};

function createComponent({
  props = { ...mockProps },
  stubs = defaultStubs,
  slots = defaultSlots,
} = {}) {
  return mount(BaseToken, {
    propsData: {
      ...props,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: jest.fn(),
      suggestionsListClass: 'custom-class',
    },
    stubs,
    slots,
  });
}

describe('BaseToken', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent({
      props: {
        ...mockProps,
        value: { data: `"${mockRegularLabel.title}"` },
        suggestions: mockLabels,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('calls `getRecentlyUsedSuggestions` to populate `recentSuggestions` when `recentSuggestionsStorageKey` is defined', () => {
      expect(getRecentlyUsedSuggestions).toHaveBeenCalledWith(mockStorageKey);
    });
  });

  describe('computed', () => {
    describe('currentTokenValue', () => {
      it('calls `fnCurrentTokenValue` when it is provided', () => {
        // We're disabling lint to trigger computed prop execution for this test.
        // eslint-disable-next-line no-unused-vars
        const { currentTokenValue } = wrapper.vm;

        expect(wrapper.vm.fnCurrentTokenValue).toHaveBeenCalledWith(`"${mockRegularLabel.title}"`);
      });
    });

    describe('activeTokenValue', () => {
      it('calls `fnActiveTokenValue` when it is provided', async () => {
        const mockFnActiveTokenValue = jest.fn();

        wrapper.setProps({
          fnActiveTokenValue: mockFnActiveTokenValue,
          fnCurrentTokenValue: undefined,
        });

        await wrapper.vm.$nextTick();

        expect(mockFnActiveTokenValue).toHaveBeenCalledTimes(1);
        expect(mockFnActiveTokenValue).toHaveBeenCalledWith(
          mockLabels,
          `"${mockRegularLabel.title.toLowerCase()}"`,
        );
      });
    });
  });

  describe('watch', () => {
    describe('active', () => {
      let wrapperWithTokenActive;

      beforeEach(() => {
        wrapperWithTokenActive = createComponent({
          props: {
            ...mockProps,
            value: { data: `"${mockRegularLabel.title}"` },
            active: true,
          },
        });
      });

      afterEach(() => {
        wrapperWithTokenActive.destroy();
      });

      it('emits `fetch-suggestions` event on the component when value of this prop is changed to false and `suggestions` array is empty', async () => {
        wrapperWithTokenActive.setProps({
          active: false,
        });

        await wrapperWithTokenActive.vm.$nextTick();

        expect(wrapperWithTokenActive.emitted('fetch-suggestions')).toBeTruthy();
        expect(wrapperWithTokenActive.emitted('fetch-suggestions')).toEqual([
          [`"${mockRegularLabel.title}"`],
        ]);
      });
    });
  });

  describe('methods', () => {
    describe('handleTokenValueSelected', () => {
      it('calls `setTokenValueToRecentlyUsed` when `recentSuggestionsStorageKey` is defined', () => {
        const mockTokenValue = {
          id: 1,
          title: 'Foo',
        };

        wrapper.vm.handleTokenValueSelected(mockTokenValue);

        expect(setTokenValueToRecentlyUsed).toHaveBeenCalledWith(mockStorageKey, mockTokenValue);
      });

      it('does not add token from preloadedSuggestions', async () => {
        const mockTokenValue = {
          id: 1,
          title: 'Foo',
        };

        wrapper.setProps({
          preloadedSuggestions: [mockTokenValue],
        });

        await wrapper.vm.$nextTick();

        wrapper.vm.handleTokenValueSelected(mockTokenValue);

        expect(setTokenValueToRecentlyUsed).not.toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders gl-filtered-search-token component', () => {
      const wrapperWithNoStubs = createComponent({
        stubs: {},
      });
      const glFilteredSearchToken = wrapperWithNoStubs.find(GlFilteredSearchToken);

      expect(glFilteredSearchToken.exists()).toBe(true);
      expect(glFilteredSearchToken.props('config')).toBe(mockLabelToken);

      wrapperWithNoStubs.destroy();
    });

    it('renders `view-token` slot when present', () => {
      expect(wrapper.find('.js-view-token').exists()).toBe(true);
    });

    it('renders `view` slot when present', () => {
      expect(wrapper.find('.js-view').exists()).toBe(true);
    });

    describe('events', () => {
      let wrapperWithNoStubs;

      beforeEach(() => {
        wrapperWithNoStubs = createComponent({
          stubs: { Portal: true },
        });
      });

      afterEach(() => {
        wrapperWithNoStubs.destroy();
      });

      it('emits `fetch-suggestions` event on component after a delay when component emits `input` event', async () => {
        jest.useFakeTimers();

        wrapperWithNoStubs.find(GlFilteredSearchToken).vm.$emit('input', { data: 'foo' });
        await wrapperWithNoStubs.vm.$nextTick();

        jest.runAllTimers();

        expect(wrapperWithNoStubs.emitted('fetch-suggestions')).toBeTruthy();
        expect(wrapperWithNoStubs.emitted('fetch-suggestions')[2]).toEqual(['foo']);
      });
    });
  });
});
