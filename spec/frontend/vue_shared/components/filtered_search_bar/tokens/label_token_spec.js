import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
  GlLabel,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/sidebar/components/labels/labels_select_vue/mock_data';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

import { mockLabelToken } from '../mock_data';

jest.mock('~/alert');
const defaultStubs = {
  Portal: true,
  BaseToken,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

function createComponent(options = {}) {
  const {
    config = mockLabelToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
    listeners = {},
  } = options;
  return mount(LabelToken, {
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
      hasScopedLabelsFeature: false,
    },
    stubs,
    listeners,
  });
}

describe('LabelToken', () => {
  let mock;
  let wrapper;
  const defaultLabels = OPTIONS_NONE_ANY;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const findSuggestions = () => wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findTokenSegments = () => wrapper.findAllComponents(GlFilteredSearchTokenSegment);
  const triggerFetchLabels = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  afterEach(() => {
    mock.restore();
  });

  describe('methods', () => {
    describe('getActiveLabel', () => {
      it('returns label object from labels array based on provided `currentValue` param', () => {
        wrapper = createComponent();

        expect(findBaseToken().props('getActiveTokenValue')(mockLabels, 'Foo Label')).toEqual(
          mockRegularLabel,
        );
      });
    });

    describe('getLabelName', () => {
      it('returns value of `name` or `title` property present in provided label param', async () => {
        const customMockLabels = [
          { title: 'Title with no name label' },
          { name: 'Name Label', title: 'Title with name label' },
        ];

        wrapper = createComponent({
          active: true,
          config: {
            ...mockLabelToken,
            fetchLabels: jest.fn().mockResolvedValue({ data: customMockLabels }),
          },
          stubs: { Portal: true },
        });

        await waitForPromises();

        const suggestions = findSuggestions();
        const indexWithTitle = defaultLabels.length;
        const indexWithName = defaultLabels.length + 1;

        expect(suggestions.at(indexWithTitle).text()).toBe(customMockLabels[0].title);
        expect(suggestions.at(indexWithName).text()).toBe(customMockLabels[1].name);
      });
    });

    describe('fetchLabels', () => {
      describe('when request is successful', () => {
        const searchTerm = 'foo';

        beforeEach(async () => {
          wrapper = createComponent({
            config: {
              fetchLabels: jest.fn().mockResolvedValue({ data: mockLabels }),
            },
          });
          await triggerFetchLabels(searchTerm);
        });

        it('calls `config.fetchLabels` with provided searchTerm param', () => {
          expect(findBaseToken().props('config').fetchLabels).toHaveBeenCalledWith(searchTerm);
        });

        it('sets response to `labels`', () => {
          expect(findBaseToken().props('suggestions')).toEqual(mockLabels);
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });

      describe('when request fails', () => {
        beforeEach(async () => {
          wrapper = createComponent({
            config: {
              fetchLabels: jest.fn().mockRejectedValue({}),
            },
          });
          await triggerFetchLabels();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching labels.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: `"${mockRegularLabel.title}"` },
        config: {
          initialLabels: mockLabels,
        },
      });

      await nextTick();
    });

    it('renders base-token component', () => {
      const baseTokenEl = findBaseToken();

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        suggestions: mockLabels,
        getActiveTokenValue: wrapper.vm.getActiveLabel,
      });
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = findTokenSegments();

      expect(tokenSegments).toHaveLength(3); // Label, =, "Foo Label"
      expect(tokenSegments.at(2).text()).toBe(`${mockRegularLabel.title}`); // "Foo Label"
      expect(tokenSegments.at(2).findComponent(GlLabel).props('backgroundColor')).toBe(
        mockRegularLabel.color,
      );
    });

    it('renders provided defaultLabels as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockLabelToken, defaultLabels },
        stubs: { Portal: true },
      });
      const tokenSegments = findTokenSegments();
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = findSuggestions();

      expect(suggestions).toHaveLength(defaultLabels.length);
      defaultLabels.forEach((label, index) => {
        expect(suggestions.at(index).text()).toBe(label.text);
      });
    });

    it('does not render divider when no defaultLabels', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockLabelToken, defaultLabels: [] },
        stubs: { Portal: true },
      });
      const tokenSegments = findTokenSegments();
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `OPTIONS_NONE_ANY` as default suggestions', () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockLabelToken },
        stubs: { Portal: true },
      });
      const tokenSegments = findTokenSegments();
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      const suggestions = findSuggestions();

      expect(suggestions).toHaveLength(OPTIONS_NONE_ANY.length);
      OPTIONS_NONE_ANY.forEach((label, index) => {
        expect(suggestions.at(index).text()).toBe(label.text);
      });
    });

    it('emits listeners in the base-token', () => {
      const mockInput = jest.fn();
      wrapper = createComponent({
        listeners: {
          input: mockInput,
        },
      });
      findBaseToken().vm.$emit('input', [{ data: 'mockData', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'mockData', operator: '=' }]);
    });
  });
});
