import { GlFilteredSearchToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';

import { DEFAULT_LABELS } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  getRecentlyUsedTokenValues,
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
  tokenConfig: mockLabelToken,
  tokenValue: { data: '' },
  tokenActive: false,
  tokensListLoading: false,
  tokenValues: [],
  fnActiveTokenValue: jest.fn(),
  defaultTokenValues: DEFAULT_LABELS,
  recentTokenValuesStorageKey: mockStorageKey,
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
        tokenValue: { data: `"${mockRegularLabel.title}"` },
        tokenValues: mockLabels,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('calls `getRecentlyUsedTokenValues` to populate `recentTokenValues` when `recentTokenValuesStorageKey` is defined', () => {
      expect(getRecentlyUsedTokenValues).toHaveBeenCalledWith(mockStorageKey);
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
        wrapper.setProps({
          fnCurrentTokenValue: undefined,
        });

        await wrapper.vm.$nextTick();

        // We're disabling lint to trigger computed prop execution for this test.
        // eslint-disable-next-line no-unused-vars
        const { activeTokenValue } = wrapper.vm;

        expect(wrapper.vm.fnActiveTokenValue).toHaveBeenCalledWith(
          mockLabels,
          `"${mockRegularLabel.title.toLowerCase()}"`,
        );
      });
    });
  });

  describe('watch', () => {
    describe('tokenActive', () => {
      let wrapperWithTokenActive;

      beforeEach(() => {
        wrapperWithTokenActive = createComponent({
          props: {
            ...mockProps,
            tokenActive: true,
            tokenValue: { data: `"${mockRegularLabel.title}"` },
          },
        });
      });

      afterEach(() => {
        wrapperWithTokenActive.destroy();
      });

      it('emits `fetch-token-values` event on the component when value of this prop is changed to false and `tokenValues` array is empty', async () => {
        wrapperWithTokenActive.setProps({
          tokenActive: false,
        });

        await wrapperWithTokenActive.vm.$nextTick();

        expect(wrapperWithTokenActive.emitted('fetch-token-values')).toBeTruthy();
        expect(wrapperWithTokenActive.emitted('fetch-token-values')).toEqual([
          [`"${mockRegularLabel.title}"`],
        ]);
      });
    });
  });

  describe('methods', () => {
    describe('handleTokenValueSelected', () => {
      it('calls `setTokenValueToRecentlyUsed` when `recentTokenValuesStorageKey` is defined', () => {
        const mockTokenValue = {
          id: 1,
          title: 'Foo',
        };

        wrapper.vm.handleTokenValueSelected(mockTokenValue);

        expect(setTokenValueToRecentlyUsed).toHaveBeenCalledWith(mockStorageKey, mockTokenValue);
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

      it('emits `fetch-token-values` event on component after a delay when component emits `input` event', async () => {
        jest.useFakeTimers();

        wrapperWithNoStubs.find(GlFilteredSearchToken).vm.$emit('input', { data: 'foo' });
        await wrapperWithNoStubs.vm.$nextTick();

        jest.runAllTimers();

        expect(wrapperWithNoStubs.emitted('fetch-token-values')).toBeTruthy();
        expect(wrapperWithNoStubs.emitted('fetch-token-values')[1]).toEqual(['foo']);
      });
    });
  });
});
