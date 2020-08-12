import { mount } from '@vue/test-utils';
import { GlFilteredSearchToken, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';

import createFlash from '~/flash';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';

import {
  mockMilestoneToken,
  mockMilestones,
  mockRegularMilestone,
  mockEscapedMilestone,
} from '../mock_data';

jest.mock('~/flash');

const createComponent = ({
  config = mockMilestoneToken,
  value = { data: '' },
  active = false,
} = {}) =>
  mount(MilestoneToken, {
    propsData: {
      config,
      value,
      active,
    },
    provide: {
      portalName: 'fake target',
      alignSuggestions: function fakeAlignSuggestions() {},
    },
    stubs: {
      Portal: {
        template: '<div><slot></slot></div>',
      },
      GlFilteredSearchSuggestionList: {
        template: '<div></div>',
        methods: {
          getValue: () => '=',
        },
      },
    },
  });

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
        });
      });

      it('calls `createFlash` with flash error message when request fails', () => {
        jest.spyOn(wrapper.vm.config, 'fetchMilestones').mockRejectedValue({});

        wrapper.vm.fetchMilestoneBySearchTerm('foo');

        return waitForPromises().then(() => {
          expect(createFlash).toHaveBeenCalledWith('There was a problem fetching milestones.');
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
      expect(tokenSegments.at(2).text()).toBe(`%"${mockRegularMilestone.title}"`); // "4.0 RC1"
    });
  });
});
