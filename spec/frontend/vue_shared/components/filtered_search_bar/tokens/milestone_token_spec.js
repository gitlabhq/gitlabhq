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
import { sortMilestonesByDueDate } from '~/milestones/milestone_utils';

import { DEFAULT_MILESTONES } from '~/vue_shared/components/filtered_search_bar/constants';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';

import {
  mockMilestoneToken,
  mockMilestones,
  mockRegularMilestone,
  mockEscapedMilestone,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/milestones/milestone_utils');

const defaultStubs = {
  Portal: true,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

function createComponent(options = {}) {
  const {
    config = mockMilestoneToken,
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
  } = options;
  return mount(MilestoneToken, {
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

describe('MilestoneToken', () => {
  let mock;
  let wrapper;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createComponent();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('computed', () => {
    beforeEach(async () => {
      // Milestone title with spaces is always enclosed in quotations by component.
      wrapper = createComponent({ value: { data: `"${mockEscapedMilestone.title}"` } });

      wrapper.setData({
        milestones: mockMilestones,
      });

      await wrapper.vm.$nextTick();
    });

    describe('currentValue', () => {
      it('returns lowercase string for `value.data`', () => {
        expect(wrapper.vm.currentValue).toBe('"5.0 rc1"');
      });
    });

    describe('activeMilestone', () => {
      it('returns object for currently present `value.data`', () => {
        expect(wrapper.vm.activeMilestone).toEqual(mockEscapedMilestone);
      });
    });
  });

  describe('methods', () => {
    describe('fetchMilestoneBySearchTerm', () => {
      it('calls `config.fetchMilestones` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones');

        wrapper.vm.fetchMilestoneBySearchTerm('foo');

        expect(wrapper.vm.config.fetchMilestones).toHaveBeenCalledWith('foo');
      });

      it('sets response to `milestones` when request is successful', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockResolvedValue({
          data: mockMilestones,
        });

        wrapper.vm.fetchMilestoneBySearchTerm();

        return waitForPromises().then(() => {
          expect(wrapper.vm.milestones).toEqual(mockMilestones);
          expect(sortMilestonesByDueDate).toHaveBeenCalled();
        });
      });

      it('calls `createFlash` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockRejectedValue({});

        wrapper.vm.fetchMilestoneBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was a problem fetching milestones.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockRejectedValue({});

        wrapper.vm.fetchMilestoneBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(wrapper.vm.loading).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultMilestones = [
      { text: 'foo', value: 'foo' },
      { text: 'bar', value: 'baz' },
    ];

    beforeEach(async () => {
      wrapper = createComponent({ value: { data: `"${mockRegularMilestone.title}"` } });

      wrapper.setData({
        milestones: mockMilestones,
      });

      await wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.find(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Milestone, =, '%"4.0"'
      expect(tokenSegments.at(2).text()).toBe(`%${mockRegularMilestone.title}`); // "4.0 RC1"
    });

    it('renders provided defaultMilestones as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockMilestoneToken, defaultMilestones },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(defaultMilestones.length);
      defaultMilestones.forEach((milestone, index) => {
        expect(suggestions.at(index).text()).toBe(milestone.text);
      });
    });

    it('does not render divider when no defaultMilestones', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockMilestoneToken, defaultMilestones: [] },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.find(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `DEFAULT_MILESTONES` as default suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockMilestoneToken },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await wrapper.vm.$nextTick();

      const suggestions = wrapper.findAll(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(DEFAULT_MILESTONES.length);
      DEFAULT_MILESTONES.forEach((milestone, index) => {
        expect(suggestions.at(index).text()).toBe(milestone.text);
      });
    });
  });
});
