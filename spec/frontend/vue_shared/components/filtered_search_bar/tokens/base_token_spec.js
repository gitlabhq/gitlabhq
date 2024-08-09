import {
  GlFilteredSearchToken,
  GlLoadingIcon,
  GlFilteredSearchSuggestion,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlDropdownText,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/sidebar/components/labels/labels_select_vue/mock_data';

import {
  OPTIONS_NONE_ANY,
  OPERATOR_IS,
  OPERATOR_NOT,
  OPERATOR_OR,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  getRecentlyUsedSuggestions,
  setTokenValueToRecentlyUsed,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import { mockLabelToken } from '../mock_data';

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils', () => ({
  getRecentlyUsedSuggestions: jest.fn(),
  setTokenValueToRecentlyUsed: jest.fn(),
  stripQuotes: jest.requireActual('~/lib/utils/text_utility').stripQuotes,
}));

const mockStorageKey = 'recent-tokens-label_name';

const defaultStubs = {
  Portal: true,
  GlFilteredSearchToken: {
    template: `
      <div>
        <slot name="view-token"></slot>
        <slot name="view"></slot>
        <slot name="suggestions"></slot>
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

const mockSuggestionListTestId = 'suggestion-list';
const defaultSlots = {
  'view-token': `
    <div class="js-view-token">${mockRegularLabel.title}</div>
  `,
  view: `
    <div class="js-view">${mockRegularLabel.title}</div>
  `,
};

const defaultScopedSlots = {
  'suggestions-list': `<div data-testid="${mockSuggestionListTestId}" :data-suggestions="JSON.stringify(props.suggestions)"></div>`,
};

const mockConfig = { ...mockLabelToken, recentSuggestionsStorageKey: mockStorageKey };
const mockProps = {
  config: mockConfig,
  value: { data: '' },
  active: false,
  suggestions: [],
  suggestionsLoading: false,
  defaultSuggestions: OPTIONS_NONE_ANY,
  getActiveTokenValue: (labels, data) => labels.find((label) => label.title === data),
  cursorPosition: 'start',
};

function createComponent({
  props = {},
  data = {},
  stubs = defaultStubs,
  slots = defaultSlots,
  scopedSlots = defaultScopedSlots,
  mountFn = mount,
} = {}) {
  return mountFn(BaseToken, {
    propsData: {
      ...mockProps,
      ...props,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: jest.fn(),
      suggestionsListClass: () => 'custom-class',
      termsAsTokens: () => false,
      filteredSearchSuggestionListInstance: {
        register: jest.fn(),
        unregister: jest.fn(),
      },
    },
    data() {
      return data;
    },
    stubs,
    slots,
    scopedSlots,
  });
}

describe('BaseToken', () => {
  let wrapper;

  const findGlFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findMockSuggestionList = () => wrapper.findByTestId(mockSuggestionListTestId);

  const getMockSuggestionListSuggestions = () =>
    JSON.parse(findMockSuggestionList().attributes('data-suggestions'));

  describe('data', () => {
    it('calls `getRecentlyUsedSuggestions` to populate `recentSuggestions` when `recentSuggestionsStorageKey` is defined', () => {
      wrapper = createComponent();

      expect(getRecentlyUsedSuggestions).toHaveBeenCalledWith(
        mockStorageKey,
        expect.anything(),
        expect.anything(),
      );
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

      it('uses last item in list when value is an array', () => {
        const mockGetActiveTokenValue = jest.fn();

        const config = { ...mockConfig, multiSelect: true };

        wrapper = createComponent({
          props: {
            config,
            value: { data: mockLabels.map((l) => l.title), operator: '||' },
            suggestions: mockLabels,
            getActiveTokenValue: mockGetActiveTokenValue,
          },
        });

        const lastTitle = mockLabels[mockLabels.length - 1].title;

        expect(mockGetActiveTokenValue).toHaveBeenCalledTimes(1);
        expect(mockGetActiveTokenValue).toHaveBeenCalledWith(mockLabels, lastTitle);
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

  describe('suggestions', () => {
    describe('with suggestions disabled', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: {
            config: {
              suggestionsDisabled: true,
            },
            suggestions: [{ id: 'Foo' }],
          },
          mountFn: shallowMountExtended,
        });
      });

      it('does not render suggestions', () => {
        expect(findMockSuggestionList().exists()).toBe(false);
      });
    });

    describe('with available suggestions', () => {
      let mockSuggestions;

      describe.each`
        hasSuggestions | searchKey | shouldRenderSuggestions
        ${true}        | ${null}   | ${true}
        ${true}        | ${'foo'}  | ${true}
        ${false}       | ${null}   | ${false}
      `(
        `when hasSuggestions is $hasSuggestions`,
        ({ hasSuggestions, searchKey, shouldRenderSuggestions }) => {
          beforeEach(async () => {
            mockSuggestions = hasSuggestions ? [{ id: 'Foo' }] : [];
            const props = { defaultSuggestions: [], suggestions: mockSuggestions };

            getRecentlyUsedSuggestions.mockReturnValue([]);
            wrapper = createComponent({ props, mountFn: shallowMountExtended, stubs: {} });
            findGlFilteredSearchToken().vm.$emit('input', { data: searchKey });

            await nextTick();
          });

          it(`${shouldRenderSuggestions ? 'should' : 'should not'} render suggestions`, () => {
            expect(findMockSuggestionList().exists()).toBe(shouldRenderSuggestions);

            if (shouldRenderSuggestions) {
              expect(getMockSuggestionListSuggestions()).toEqual(mockSuggestions);
            }
          });
        },
      );

      it('limits the length of the rendered list using config.maxSuggestions', () => {
        mockSuggestions = ['a', 'b', 'c', 'd'].map((id) => ({ id }));

        const maxSuggestions = 2;
        const config = { ...mockConfig, maxSuggestions };
        const props = { defaultSuggestions: [], suggestions: mockSuggestions, config };

        getRecentlyUsedSuggestions.mockReturnValue([]);
        wrapper = createComponent({ props, mountFn: shallowMountExtended, stubs: {} });

        expect(findMockSuggestionList().exists()).toBe(true);
        expect(getMockSuggestionListSuggestions().length).toEqual(maxSuggestions);
      });
    });

    describe('with preloaded suggestions', () => {
      const mockPreloadedSuggestions = [{ id: 'Foo' }, { id: 'Bar' }];

      describe.each`
        searchKey | shouldRenderPreloadedSuggestions
        ${null}   | ${true}
        ${'foo'}  | ${false}
      `('when searchKey is $searchKey', ({ shouldRenderPreloadedSuggestions, searchKey }) => {
        beforeEach(async () => {
          const props = { preloadedSuggestions: mockPreloadedSuggestions };
          wrapper = createComponent({ props, mountFn: shallowMountExtended, stubs: {} });
          findGlFilteredSearchToken().vm.$emit('input', { data: searchKey });

          await nextTick();
        });

        it(`${
          shouldRenderPreloadedSuggestions ? 'should' : 'should not'
        } render preloaded suggestions`, () => {
          expect(findMockSuggestionList().exists()).toBe(shouldRenderPreloadedSuggestions);

          if (shouldRenderPreloadedSuggestions) {
            expect(getMockSuggestionListSuggestions()).toEqual(mockPreloadedSuggestions);
          }
        });
      });
    });

    describe('with recent suggestions', () => {
      let mockSuggestions;

      describe.each`
        searchKey | recentEnabled | shouldRenderRecentSuggestions
        ${null}   | ${true}       | ${true}
        ${'foo'}  | ${true}       | ${false}
        ${null}   | ${false}      | ${false}
      `(
        'when searchKey is $searchKey and recentEnabled is $recentEnabled',
        ({ shouldRenderRecentSuggestions, recentEnabled, searchKey }) => {
          beforeEach(async () => {
            const props = { value: { data: '', operator: '=' }, defaultSuggestions: [] };

            if (recentEnabled) {
              mockSuggestions = [{ id: 'Foo' }, { id: 'Bar' }];
              getRecentlyUsedSuggestions.mockReturnValue(mockSuggestions);
            }

            props.config = { recentSuggestionsStorageKey: recentEnabled ? mockStorageKey : null };

            wrapper = createComponent({ props, mountFn: shallowMountExtended, stubs: {} });
            findGlFilteredSearchToken().vm.$emit('input', { data: searchKey });

            await nextTick();
          });

          it(`${
            shouldRenderRecentSuggestions ? 'should' : 'should not'
          } render recent suggestions`, () => {
            expect(findMockSuggestionList().exists()).toBe(shouldRenderRecentSuggestions);
            expect(wrapper.findComponent(GlDropdownSectionHeader).exists()).toBe(
              shouldRenderRecentSuggestions,
            );
            expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(
              shouldRenderRecentSuggestions,
            );

            if (shouldRenderRecentSuggestions) {
              expect(getMockSuggestionListSuggestions()).toEqual(mockSuggestions);
            }
          });
        },
      );
    });

    describe('with default suggestions', () => {
      describe.each`
        operator        | shouldRenderFilteredSearchSuggestion
        ${OPERATOR_IS}  | ${true}
        ${OPERATOR_NOT} | ${false}
        ${OPERATOR_OR}  | ${false}
      `('when operator is $operator', ({ shouldRenderFilteredSearchSuggestion, operator }) => {
        beforeEach(() => {
          const props = {
            defaultSuggestions: OPTIONS_NONE_ANY,
            value: { data: '', operator },
          };

          wrapper = createComponent({ props, mountFn: shallowMountExtended });
        });

        it(`${
          shouldRenderFilteredSearchSuggestion ? 'should' : 'should not'
        } render GlFilteredSearchSuggestion`, () => {
          const filteredSearchSuggestions = wrapper.findAllComponents(
            GlFilteredSearchSuggestion,
          ).wrappers;

          if (shouldRenderFilteredSearchSuggestion) {
            expect(filteredSearchSuggestions.map((c) => c.props())).toMatchObject(
              OPTIONS_NONE_ANY.map((opt) => ({ value: opt.value })),
            );
          } else {
            expect(filteredSearchSuggestions).toHaveLength(0);
          }
        });
      });
    });

    describe('with no suggestions', () => {
      it.each`
        data                       | expected
        ${{ searchKey: 'search' }} | ${'No matches found'}
        ${{ hasFetched: true }}    | ${'No suggestions found'}
      `('shows $expected text', ({ data, expected }) => {
        wrapper = createComponent({
          props: {
            config: { recentSuggestionsStorageKey: null },
            defaultSuggestions: [],
            preloadedSuggestions: [],
            suggestions: [],
            suggestionsLoading: false,
          },
          data,
          mountFn: shallowMountExtended,
        });

        expect(wrapper.findComponent(GlDropdownText).text()).toBe(expected);
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

    it('renders  `footer` slot when present', () => {
      wrapper = createComponent({ slots: { footer: "<div class='custom-footer' />" } });

      expect(wrapper.find('.custom-footer').exists()).toBe(true);
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
          findGlFilteredSearchToken().vm.$emit('input', { data: 'foo' });
          await nextTick();

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
          findGlFilteredSearchToken().vm.$emit('input', { data: 'foo' });
          await nextTick();

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

        it('does not emit `fetch-suggestions` when value is array', () => {
          expect(wrapper.emitted('fetch-suggestions')).toEqual([[''], ['']]);

          findGlFilteredSearchToken().vm.$emit('input', { data: ['first item'] });

          expect(wrapper.emitted('fetch-suggestions')).toEqual([[''], ['']]);
        });
      });
    });
  });
});
