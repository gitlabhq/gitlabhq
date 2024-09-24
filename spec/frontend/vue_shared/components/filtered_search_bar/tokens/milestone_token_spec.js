import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlFilteredSearchTokenSegment,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { sortMilestonesByDueDate } from '~/milestones/utils';
import searchMilestonesQuery from '~/issues/list/queries/search_milestones.query.graphql';
import { DEFAULT_MILESTONES } from '~/vue_shared/components/filtered_search_bar/constants';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

import {
  mockMilestoneToken,
  mockMilestones,
  mockRegularMilestone,
  projectMilestonesResponse,
  mockDuplicateMilestones,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
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

const milestonesQueryHandler = jest.fn().mockResolvedValue(projectMilestonesResponse);
const mockApollo = createMockApollo([[searchMilestonesQuery, milestonesQueryHandler]]);

function createComponent(options = {}) {
  const {
    config = { ...mockMilestoneToken, shouldSkipSort: true },
    value = { data: '' },
    active = false,
    stubs = defaultStubs,
  } = options;
  return mount(MilestoneToken, {
    apolloProvider: mockApollo,
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
    },
    stubs,
  });
}

describe('MilestoneToken', () => {
  let wrapper;

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const triggerFetchMilestones = (searchTerm = null) => {
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
    return waitForPromises();
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('methods', () => {
    describe('fetchMilestones', () => {
      it('sets loading state', async () => {
        wrapper = createComponent({
          config: {
            fetchMilestones: jest.fn().mockResolvedValue(new Promise(() => {})),
          },
        });
        await nextTick();

        expect(findBaseToken().props('suggestionsLoading')).toBe(true);
      });

      describe('when there are duplicate milestones in the data', () => {
        it('only shows the milestone title once in results', async () => {
          wrapper = createComponent({
            config: {
              fetchMilestones: jest.fn().mockResolvedValue({
                data: mockDuplicateMilestones,
              }),
            },
          });

          await triggerFetchMilestones();

          expect(findBaseToken().props('suggestions')).toHaveLength(1);
          expect(findBaseToken().props('suggestions')[0].title).toEqual('99.0');
        });
      });

      describe('when config.shouldSkipSort is true', () => {
        it('does not call sortMilestonesByDueDate', async () => {
          wrapper = createComponent({
            config: {
              shouldSkipSort: true,
              fetchMilestones: jest.fn().mockResolvedValue({ data: mockMilestones }),
            },
          });

          await triggerFetchMilestones();

          expect(sortMilestonesByDueDate).toHaveBeenCalledTimes(0);
        });
      });

      describe('default - when fetchMilestones function is not provided in config', () => {
        beforeEach(() => {
          wrapper = createComponent({});
          return triggerFetchMilestones();
        });

        it('calls searchMilestonesQuery to fetch milestones', () => {
          expect(milestonesQueryHandler).toHaveBeenCalledWith({
            fullPath: mockMilestoneToken.fullPath,
            isProject: mockMilestoneToken.isProject,
            search: null,
          });
        });

        it('calls searchMilestonesQuery with search parameter when provided', async () => {
          const searchTerm = 'foo';

          await triggerFetchMilestones(searchTerm);

          expect(milestonesQueryHandler).toHaveBeenCalledWith({
            fullPath: mockMilestoneToken.fullPath,
            isProject: mockMilestoneToken.isProject,
            search: searchTerm,
          });
        });
      });

      describe('when request is successful', () => {
        const searchTerm = 'foo';

        beforeEach(() => {
          wrapper = createComponent({
            config: {
              shouldSkipSort: false,
              fetchMilestones: jest.fn().mockResolvedValue({ data: mockMilestones }),
            },
          });
          return triggerFetchMilestones(searchTerm);
        });

        it('calls `config.fetchMilestones` with provided searchTerm param', () => {
          expect(findBaseToken().props('config').fetchMilestones).toHaveBeenCalledWith(searchTerm);
        });

        it('sets response to `milestones`', () => {
          expect(sortMilestonesByDueDate).toHaveBeenCalled();
          expect(findBaseToken().props('suggestions')).toEqual(mockMilestones);
        });
      });

      describe('when request fails', () => {
        beforeEach(() => {
          wrapper = createComponent({
            config: {
              fetchMilestones: jest.fn().mockRejectedValue({}),
            },
          });
          return triggerFetchMilestones();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching milestones.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const defaultMilestones = [
      { text: 'foo', value: 'foo' },
      { text: 'bar', value: 'baz' },
    ];

    beforeEach(() => {
      wrapper = createComponent({
        value: { data: `"${mockRegularMilestone.title}"` },
        config: {
          initialMilestones: mockMilestones,
        },
      });
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
          const activeToken = findBaseToken().props('getActiveTokenValue')([], value);

          expect(activeToken.title).toEqual(title);
        });
      });
    });
  });
});
