import Vuex from 'vuex';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/deploy_freeze/store';
import { mockTimezoneData } from '../mock_data';

import { GlDropdownItem, GlNewDropdown } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Deploy freeze timezone dropdown', () => {
  let wrapper;
  let store;

  const createComponent = (searchTerm, selectedTimezone) => {
    store = createStore({
      projectId: '8',
      timezoneData: mockTimezoneData,
    });
    wrapper = shallowMount(TimezoneDropdown, {
      store,
      localVue,
      propsData: {
        value: selectedTimezone,
        timezoneData: mockTimezoneData,
      },
    });

    wrapper.setData({ searchTerm });
  };

  const findAllDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findDropdownItemByIndex = index => wrapper.findAll(GlDropdownItem).at(index);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('No time zones found', () => {
    beforeEach(() => {
      createComponent('UTC timezone');
    });

    it('renders empty results message', () => {
      expect(findDropdownItemByIndex(0).text()).toBe('No matching results');
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent('');
    });

    it('renders all timezones when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(mockTimezoneData.length);
    });
  });

  describe('Time zones found', () => {
    beforeEach(() => {
      createComponent('Alaska');
    });

    it('renders only the time zone searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe('[UTC -8] Alaska');
    });

    it('should not display empty results message', () => {
      expect(wrapper.find('[data-testid="noMatchingResults"]').exists()).toBe(false);
    });

    describe('Custom events', () => {
      it('should emit input if a time zone is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');
        expect(wrapper.emitted('input')).toEqual([
          [
            {
              formattedTimezone: '[UTC -8] Alaska',
              identifier: 'America/Juneau',
            },
          ],
        ]);
      });
    });
  });

  describe('Selected time zone', () => {
    beforeEach(() => {
      createComponent('', 'Alaska');
    });

    it('renders selected time zone as dropdown label', () => {
      expect(wrapper.find(GlNewDropdown).vm.text).toBe('Alaska');
    });
  });
});
