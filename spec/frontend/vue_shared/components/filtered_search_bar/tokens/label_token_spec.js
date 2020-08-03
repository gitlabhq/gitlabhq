import { mount } from '@vue/test-utils';
import { GlFilteredSearchToken, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';

import createFlash from '~/flash';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

import {
  mockRegularLabel,
  mockLabels,
} from 'jest/vue_shared/components/sidebar/labels_select_vue/mock_data';

import { mockLabelToken } from '../mock_data';

jest.mock('~/flash');

const createComponent = ({ config = mockLabelToken, value = { data: '' }, active = false } = {}) =>
  mount(LabelToken, {
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

describe('LabelToken', () => {
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
      // Label title with spaces is always enclosed in quotations by component.
      wrapper = createComponent({ value: { data: `"${mockRegularLabel.title}"` } });

      wrapper.setData({
        labels: mockLabels,
      });

      await wrapper.vm.$nextTick();
    });

    describe('currentValue', () => {
      it('returns lowercase string for `value.data`', () => {
        expect(wrapper.vm.currentValue).toBe('"foo label"');
      });
    });

    describe('activeLabel', () => {
      it('returns object for currently present `value.data`', () => {
        expect(wrapper.vm.activeLabel).toEqual(mockRegularLabel);
      });
    });

    describe('containerStyle', () => {
      it('returns object containing `backgroundColor` and `color` properties based on `activeLabel` value', () => {
        expect(wrapper.vm.containerStyle).toEqual({
          backgroundColor: mockRegularLabel.color,
          color: mockRegularLabel.textColor,
        });
      });

      it('returns empty object when `activeLabel` is not set', async () => {
        wrapper.setData({
          labels: [],
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.containerStyle).toEqual({});
      });
    });
  });

  describe('methods', () => {
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
          expect(createFlash).toHaveBeenCalledWith('There was a problem fetching labels.');
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
    beforeEach(async () => {
      wrapper = createComponent({ value: { data: `"${mockRegularLabel.title}"` } });

      wrapper.setData({
        labels: mockLabels,
      });

      await wrapper.vm.$nextTick();
    });

    it('renders gl-filtered-search-token component', () => {
      expect(wrapper.find(GlFilteredSearchToken).exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAll(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3); // Label, =, "Foo Label"
      expect(tokenSegments.at(2).text()).toBe(`~${mockRegularLabel.title}`); // "Foo Label"
      expect(
        tokenSegments
          .at(2)
          .find('.gl-token')
          .attributes('style'),
      ).toBe('background-color: rgb(186, 218, 85); color: rgb(255, 255, 255);');
    });
  });
});
