import { GlDropdownItem, GlDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import { formatTimezone } from '~/lib/utils/datetime_utility';
import { findTzByName, timezoneDataFixture } from './helpers';

describe('Deploy freeze timezone dropdown', () => {
  let wrapper;
  let store;

  const createComponent = (searchTerm, selectedTimezone) => {
    wrapper = shallowMountExtended(TimezoneDropdown, {
      store,
      propsData: {
        value: selectedTimezone,
        timezoneData: timezoneDataFixture,
        name: 'user[timezone]',
      },
    });

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({ searchTerm });
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findEmptyResultsItem = () => wrapper.findByTestId('noMatchingResults');
  const findHiddenInput = () => wrapper.find('input');

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
      expect(findAllDropdownItems()).toHaveLength(timezoneDataFixture.length);
    });
  });

  describe('Time zones found', () => {
    beforeEach(() => {
      createComponent('Alaska');
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
    beforeEach(() => {
      createComponent('', 'Berlin');
    });

    it('renders empty selections', () => {
      expect(wrapper.findComponent(GlDropdown).props().text).toBe('Select timezone');
    });

    it('preserves initial value in the associated input', () => {
      expect(findHiddenInput().attributes('value')).toBe('Berlin');
    });
  });

  describe('Selected time zone found', () => {
    beforeEach(() => {
      createComponent('', 'Europe/Berlin');
    });

    it('renders selected time zone as dropdown label', () => {
      expect(wrapper.findComponent(GlDropdown).props().text).toBe('[UTC+2] Berlin');
    });
  });
});
