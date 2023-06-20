import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { formatTimezone } from '~/lib/utils/datetime_utility';
import { findTzByName, timezoneDataFixture } from './helpers';

describe('Deploy freeze timezone dropdown', () => {
  let wrapper;
  let store;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSearchBox = () => wrapper.findByTestId('listbox-search-input');

  const createComponent = async (searchTerm, selectedTimezone) => {
    wrapper = shallowMountExtended(TimezoneDropdown, {
      store,
      propsData: {
        value: selectedTimezone,
        timezoneData: timezoneDataFixture,
        name: 'user[timezone]',
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });

    findSearchBox().vm.$emit('input', searchTerm);
    await nextTick();
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findDropdownItemByIndex = (index) => findAllDropdownItems().at(index);
  const findEmptyResultsItem = () => wrapper.findByTestId('listbox-no-results-text');
  const findHiddenInput = () => wrapper.find('input');

  describe('No time zones found', () => {
    beforeEach(async () => {
      await createComponent('UTC timezone');
    });

    it('renders empty results message', () => {
      expect(findEmptyResultsItem().exists()).toBe(true);
      expect(findEmptyResultsItem().text()).toBe('No matching results');
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
        const payload = formatTimezone(selectedTz);

        findDropdown().vm.$emit('select', payload);
        expect(wrapper.emitted('input')).toEqual([
          [
            {
              formattedTimezone: payload,
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
      expect(findDropdown().props('toggleText')).toBe('Select timezone');
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
      expect(findDropdown().props('toggleText')).toBe('[UTC+2] Berlin');
    });

    it('adds a checkmark to the selected option', async () => {
      findDropdown().vm.$emit('select', formatTimezone(findTzByName('Abu Dhabi')));
      await nextTick();

      expect(findDropdownItemByIndex(0).props('isSelected')).toBe(true);
    });
  });
});
