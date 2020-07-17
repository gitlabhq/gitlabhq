import Vuex from 'vuex';
import DeployFreezeTimezoneDropdown from '~/deploy_freeze/components/deploy_freeze_timezone_dropdown.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/deploy_freeze/store';
import { mockTimezoneData } from '../mock_data';

import { GlDropdownItem } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Deploy freeze timezone dropdown', () => {
  let wrapper;
  let store;

  const createComponent = term => {
    store = createStore({
      projectId: '8',
      timezoneData: mockTimezoneData,
    });
    store.state.timezoneData = mockTimezoneData;
    wrapper = shallowMount(DeployFreezeTimezoneDropdown, {
      store,
      localVue,
      propsData: {
        value: term,
        timezoneData: mockTimezoneData,
      },
    });
  };

  const findAllDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findDropdownItemByIndex = index => wrapper.findAll(GlDropdownItem).at(index);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('No enviroments found', () => {
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
      expect(wrapper.find({ ref: 'noMatchingResults' }).exists()).toBe(false);
    });

    describe('Custom events', () => {
      it('should emit selectTimezone if an environment is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');
        expect(wrapper.emitted('selectTimezone')).toEqual([
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
});
