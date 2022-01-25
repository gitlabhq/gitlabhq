import { GlFilteredSearchToken, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';

import { DEFAULT_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  getRecentlyUsedSuggestions,
  setTokenValueToRecentlyUsed,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockLabelToken } from '../mock_data';

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils', () => ({
  getRecentlyUsedSuggestions: jest.fn(),
  setTokenValueToRecentlyUsed: jest.fn(),
  stripQuotes: jest.requireActual(
    '~/vue_shared/components/filtered_search_bar/filtered_search_utils',
  ).stripQuotes,
}));

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
  config: { ...mockLabelToken, recentSuggestionsStorageKey: mockStorageKey },
  value: { data: '' },
  active: false,
  suggestions: [],
  suggestionsLoading: false,
  defaultSuggestions: DEFAULT_NONE_ANY,
  getActiveTokenValue: (labels, data) => labels.find((label) => label.title === data),
};

function createComponent({ props = {}, stubs = defaultStubs, slots = defaultSlots } = {}) {
  return mount(BaseToken, {
    propsData: {
      ...mockProps,
      ...props,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: jest.fn(),
      suggestionsListClass: () => 'custom-class',
    },
    stubs,
    slots,
  });
}

describe('BaseToken', () => {
  let wrapper;

  const findGlFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('calls `getRecentlyUsedSuggestions` to populate `recentSuggestions` when `recentSuggestionsStorageKey` is defined', () => {
      wrapper = createComponent();

      expect(getRecentlyUsedSuggestions).toHaveBeenCalledWith(mockStorageKey);
    });
  });

  describe('computed', () => {
    describe('activeTokenValue', () => {
      it('calls `getActiveTokenValue` when it is provided', () => {
        const mockGetActiveTokenValue = jest.fn();

        wrapper = createComponent({
          props: {
            value: { data: `"${mockRegularLabel.title}"` },
            suggestions: mockLabels,
            getActiveTokenValue: mockGetActiveTokenValue,
          },
        });

        expect(mockGetActiveTokenValue).toHaveBeenCalledTimes(1);
        expect(mockGetActiveTokenValue).toHaveBeenCalledWith(
          mockLabels,
          `"${mockRegularLabel.title}"`,
        );
      });
    });
  });

  describe('watch', () => {
    describe('active', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: {
            value: { data: `"${mockRegularLabel.title}"` },
            active: true,
          },
        });
      });

      it('emits `fetch-suggestions` event on the component when value of this prop is changed to false and `suggestions` array is empty', async () => {
        await wrapper.setProps({ active: false });

        expect(wrapper.emitted('fetch-suggestions')).toEqual([[`"${mockRegularLabel.title}"`]]);
      });
    });
  });

  describe('methods', () => {
    describe('handleTokenValueSelected', () => {
      const mockTokenValue = mockLabels[0];

      it('calls `setTokenValueToRecentlyUsed` when `recentSuggestionsStorageKey` is defined', () => {
        wrapper = createComponent({ props: { suggestions: mockLabels } });

        wrapper.vm.handleTokenValueSelected(mockTokenValue.title);

        expect(setTokenValueToRecentlyUsed).toHaveBeenCalledWith(mockStorageKey, mockTokenValue);
      });

      it('does not add token from preloadedSuggestions', () => {
        wrapper = createComponent({ props: { preloadedSuggestions: [mockTokenValue] } });

        wrapper.vm.handleTokenValueSelected(mockTokenValue.title);

        expect(setTokenValueToRecentlyUsed).not.toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    it('renders gl-filtered-search-token component', () => {
      wrapper = createComponent({ stubs: {} });

      expect(findGlFilteredSearchToken().props('config')).toEqual(mockProps.config);
    });

    it('renders `view-token` slot when present', () => {
      wrapper = createComponent();

      expect(wrapper.find('.js-view-token').exists()).toBe(true);
    });

    it('renders `view` slot when present', () => {
      wrapper = createComponent();

      expect(wrapper.find('.js-view').exists()).toBe(true);
    });

    it('renders loading spinner when loading', () => {
      wrapper = createComponent({
        props: {
          active: true,
          config: mockLabelToken,
          suggestionsLoading: true,
        },
        stubs: { Portal: true },
      });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    describe('events', () => {
      describe('when activeToken has been selected', () => {
        beforeEach(() => {
          wrapper = createComponent({
            props: { getActiveTokenValue: () => ({ title: '' }) },
            stubs: { Portal: true },
          });
        });

        it('does not emit `fetch-suggestions` event on component after a delay when component emits `input` event', async () => {
          jest.useFakeTimers();

          findGlFilteredSearchToken().vm.$emit('input', { data: 'foo' });
          await wrapper.vm.$nextTick();

          jest.runAllTimers();

          expect(wrapper.emitted('fetch-suggestions')).toEqual([['']]);
        });
      });

      describe('when activeToken has not been selected', () => {
        beforeEach(() => {
          wrapper = createComponent({
            stubs: { Portal: true },
          });
        });

        it('emits `fetch-suggestions` event on component after a delay when component emits `input` event', async () => {
          jest.useFakeTimers();

          findGlFilteredSearchToken().vm.$emit('input', { data: 'foo' });
          await wrapper.vm.$nextTick();

          jest.runAllTimers();

          expect(wrapper.emitted('fetch-suggestions')[2]).toEqual(['foo']);
        });

        describe('when search is started with a quote', () => {
          it('emits `fetch-suggestions` with filtered value', () => {
            findGlFilteredSearchToken().vm.$emit('input', { data: '"foo' });

            expect(wrapper.emitted('fetch-suggestions')[2]).toEqual(['foo']);
          });
        });

        describe('when search starts and ends with a quote', () => {
          it('emits `fetch-suggestions` with filtered value', () => {
            findGlFilteredSearchToken().vm.$emit('input', { data: '"foo"' });

            expect(wrapper.emitted('fetch-suggestions')[2]).toEqual(['foo']);
          });
        });
      });
    });
  });
});
