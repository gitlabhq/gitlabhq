import {
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockRegularLabel,
  mockLabels,
} from 'jest/sidebar/components/labels/labels_select_vue/mock_data';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';

import { OPTIONS_NONE_ANY } from '~/vue_shared/components/filtered_search_bar/constants';
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
      cursorPosition: 'start',
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
      suggestionsListClass: () => 'custom-class',
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
        expect(wrapper.vm.getActiveLabel(mockLabels, 'Foo Label')).toEqual(mockRegularLabel);
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

    describe('fetchLabels', () => {
      it('calls `config.fetchLabels` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels');

        wrapper.vm.fetchLabels('foo');

        expect(wrapper.vm.config.fetchLabels).toHaveBeenCalledWith('foo');
      });

      it('sets response to `labels` when request is succesful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels').mockResolvedValue(mockLabels);

        wrapper.vm.fetchLabels('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.labels).toEqual(mockLabels);
        });
      });

      it('calls `createAlert` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels').mockRejectedValue({});

        wrapper.vm.fetchLabels('foo');

        return waitForPromises().then(() => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching labels.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchLabels').mockRejectedValue({});

        wrapper.vm.fetchLabels('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.loading).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultLabels = OPTIONS_NONE_ANY;

    beforeEach(async () => {
      wrapper = createComponent({ value: { data: `"${mockRegularLabel.title}"` } });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        labels: mockLabels,
      });

      await nextTick();
    });

    it('renders base-token component', () => {
      const baseTokenEl = wrapper.findComponent(BaseToken);

      expect(baseTokenEl.exists()).toBe(true);
      expect(baseTokenEl.props()).toMatchObject({
        suggestions: mockLabels,
        getActiveTokenValue: wrapper.vm.getActiveLabel,
      });
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

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
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

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
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
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
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

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
      wrapper.findComponent(BaseToken).vm.$emit('input', [{ data: 'mockData', operator: '=' }]);

      expect(mockInput).toHaveBeenLastCalledWith([{ data: 'mockData', operator: '=' }]);
    });
  });
});
