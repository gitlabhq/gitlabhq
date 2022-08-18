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
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { sortMilestonesByDueDate } from '~/milestones/utils';

import { DEFAULT_MILESTONES } from '~/vue_shared/components/filtered_search_bar/constants';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';

import { mockMilestoneToken, mockMilestones, mockRegularMilestone } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/milestones/utils');

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
    config = { ...mockMilestoneToken, shouldSkipSort: true },
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
  } = options;
  return mount(MilestoneToken, {
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

  describe('methods', () => {
    describe('fetchMilestones', () => {
      describe('when config.shouldSkipSort is true', () => {
        beforeEach(() => {
          wrapper.vm.config.shouldSkipSort = true;
        });

        afterEach(() => {
          wrapper.vm.config.shouldSkipSort = false;
        });
        it('does not call sortMilestonesByDueDate', async () => {
          jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockResolvedValue({
            data: mockMilestones,
          });

          wrapper.vm.fetchMilestones();

          await waitForPromises();

          expect(sortMilestonesByDueDate).toHaveBeenCalledTimes(0);
        });
      });

      it('calls `config.fetchMilestones` with provided searchTerm param', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones');

        wrapper.vm.fetchMilestones('foo');

        expect(wrapper.vm.config.fetchMilestones).toHaveBeenCalledWith('foo');
      });

      it('sets response to `milestones` when request is successful', () => {
        wrapper.vm.config.shouldSkipSort = false;

        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockResolvedValue({
          data: mockMilestones,
        });
        wrapper.vm.fetchMilestones();

        return waitForPromises().then(() => {
          expect(wrapper.vm.milestones).toEqual(mockMilestones);
          expect(sortMilestonesByDueDate).toHaveBeenCalled();
        });
      });

      it('calls `createFlash` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockRejectedValue({});

        wrapper.vm.fetchMilestones('foo');

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was a problem fetching milestones.',
          });
        });
      });

      it('sets `loading` to false when request completes', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockRejectedValue({});

        wrapper.vm.fetchMilestones('foo');

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

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        milestones: mockMilestones,
      });

      await nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.findComponent(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Milestone, =, '%"4.0"'
      expect(tokenSegments.at(2).text()).toBe(`%${mockRegularMilestone.title}`); // "4.0 RC1"
    });

    it('renders provided defaultMilestones as suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockMilestoneToken, defaultMilestones },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

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
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      expect(wrapper.findComponent(GlFilteredSearchSuggestion).exists()).toBe(false);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });

    it('renders `DEFAULT_MILESTONES` as default suggestions', async () => {
      wrapper = createComponent({
        active: true,
        config: { ...mockMilestoneToken },
        stubs: { Portal: true },
      });
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);
      const suggestionsSegment = tokenSegments.at(2);
      suggestionsSegment.vm.$emit('activate');
      await nextTick();

      const suggestions = wrapper.findAllComponents(GlFilteredSearchSuggestion);

      expect(suggestions).toHaveLength(DEFAULT_MILESTONES.length);
      DEFAULT_MILESTONES.forEach((milestone, index) => {
        expect(suggestions.at(index).text()).toBe(milestone.text);
      });
    });

    describe('when getActiveMilestones is called and milestones is empty', () => {
      beforeEach(() => {
        wrapper = createComponent({
          active: true,
          config: { ...mockMilestoneToken, defaultMilestones: DEFAULT_MILESTONES },
        });
      });

      it('finds the correct value from the activeToken', () => {
        DEFAULT_MILESTONES.forEach(({ value, title }) => {
          const activeToken = wrapper.vm.getActiveMilestone([], value);

          expect(activeToken.title).toEqual(title);
        });
      });
    });
  });
});
