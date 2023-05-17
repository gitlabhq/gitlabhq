import { GlDropdownItem, GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { formatTimezone } from '~/lib/utils/datetime_utility';
import { findTzByName, timezoneDataFixture } from './helpers';

describe('Deploy freeze timezone dropdown', () => {
  let wrapper;
  let store;

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  const createComponent = async (searchTerm, selectedTimezone) => {
    wrapper = shallowMountExtended(TimezoneDropdown, {
      store,
      propsData: {
        value: selectedTimezone,
        timezoneData: timezoneDataFixture,
        name: 'user[timezone]',
      },
    });

    findSearchBox().vm.$emit('input', searchTerm);
    await nextTick();
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findEmptyResultsItem = () => wrapper.findByTestId('noMatchingResults');
  const findHiddenInput = () => wrapper.find('input');

  describe('No time zones found', () => {
    beforeEach(async () => {
      await createComponent('UTC timezone');
    });

    it('renders empty results message', () => {
      expect(findDropdownItemByIndex(0).text()).toBe('No matching results');
    });
  });

  describe('Search term is empty', () => {
    beforeEach(async () => {
      await createComponent('');
    });

    it('renders all timezones when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(timezoneDataFixture.length);
    });
  });

  describe('Time zones found', () => {
    beforeEach(async () => {
      await createComponent('Alaska');
    });

    it('renders only the time zone searched for', () => {
      const selectedTz = findTzByName('Alaska');
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe(formatTimezone(selectedTz));
    });

    it('should not display empty results message', () => {
      expect(findEmptyResultsItem().exists()).toBe(false);
    });

    describe('Custom events', () => {
      const selectedTz = findTzByName('Alaska');

      it('should emit input if a time zone is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');
        expect(wrapper.emitted('input')).toEqual([
          [
            {
              formattedTimezone: formatTimezone(selectedTz),
              identifier: selectedTz.identifier,
            },
          ],
        ]);
      });
    });
  });

  describe('Selected time zone not found', () => {
    beforeEach(async () => {
      await createComponent('', 'Berlin');
    });

    it('renders empty selections', () => {
      expect(wrapper.findComponent(GlDropdown).props().text).toBe('Select timezone');
    });

    it('preserves initial value in the associated input', () => {
      expect(findHiddenInput().attributes('value')).toBe('Berlin');
    });
  });

  describe('Selected time zone found', () => {
    beforeEach(async () => {
      await createComponent('', 'Europe/Berlin');
    });

    it('renders selected time zone as dropdown label', () => {
      expect(wrapper.findComponent(GlDropdown).props().text).toBe('[UTC+2] Berlin');
    });

    it('adds a checkmark to the selected option', async () => {
      const selectedTZOption = findAllDropdownItems().at(0);
      selectedTZOption.vm.$emit('click');
      await nextTick();
      expect(selectedTZOption.attributes('ischecked')).toBe('true');
    });
  });
});
