import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import {
  DEFAULT_LABELS,
  DEFAULT_NONE_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

import { mockLabelToken } from '../mock_data';

jest.mock('~/flash');
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
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: 'custom-class',
    },
    stubs,
    listeners,
  });
}

describe('LabelToken', () => {
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

    describe('getActiveLabel', () => {
      it('returns label object from labels array based on provided `currentValue` param', () => {
        expect(wrapper.vm.getActiveLabel(mockLabels, 'foo label')).toEqual(mockRegularLabel);
      });
    });

    describe('getLabelName', () => {
      it('returns value of `name` or `title` property present in provided label param', () => {
        let mockLabel = {
          title: 'foo',
        };

        expect(wrapper.vm.getLabelName(mockLabel)).toBe(mockLabel.title);

        mockLabel = {
          name: 'foo',
        };

        expect(wrapper.vm.getLabelName(mockLabel)).toBe(mockLabel.name);
      });
    });

    describe('fetchLabelBySearchTerm', () => {
      it('calls `config.fetchLabels` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels');

        wrapper.vm.fetchLabelBySearchTerm('foo');

        expect(wrapper.vm.config.fetchLabels).toHaveBeenCalledWith('foo');
      });

      it('sets response to `labels` when request is succesful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels').mockResolvedValue(mockLabels);

        wrapper.vm.fetchLabelBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.labels).toEqual(mockLabels);
        });
      });

      it('calls `createFlash` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels').mockRejectedValue({});

        wrapper.vm.fetchLabelBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was a problem fetching labels.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels').mockRejectedValue({});

        wrapper.vm.fetchLabelBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.loading).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultLabels = DEFAULT_NONE_ANY;

    beforeEach(async () => {
      wrapper = createComponent({ value: { data: `"${mockRegularLabel.title}"` } });

      wrapper.setData({
        labels: mockLabels,
      });

      await wrapper.vm.$nextTick();
    });

    it('renders base-token component', () => {
      const baseTokenEl = wrapper.find(BaseToken);

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        suggestions: mockLabels,
        fnActiveTokenValue: wrapper.vm.getActiveLabel,
      });
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Label, =, "Foo Label"
      expect(tokenSegments.at(2).text()).toBe(`~${mockRegularLabel.title}`); // "Foo Label"
      expect(tokenSegments.at(2).find('.gl-token').attributes('style')).toBe(
        'background-color: rgb(186, 218, 85); color: rgb(255, 255, 255);',
      );
    });

    it('renders provided defaultLabels as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockLabelToken, defaultLabels },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

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
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.find(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `DEFAULT_LABELS` as default suggestions', () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockLabelToken },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(DEFAULT_LABELS.length);
      DEFAULT_LABELS.forEach((label, index) => {
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
      wrapper.findComponent(BaseToken).vm.$emit('input', [{ data: 'mockData', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'mockData', operator: '=' }]);
    });
  });
});
