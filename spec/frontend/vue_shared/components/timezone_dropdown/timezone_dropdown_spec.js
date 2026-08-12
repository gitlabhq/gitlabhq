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
  const findSearchBox = () => wrapper.findComponentByTestId('listbox-search-input');

  const createComponent = async (searchTerm, selectedTimezone = '', propsData = {}) => {
    wrapper = shallowMountExtended(TimezoneDropdown, {
      store,
      propsData: {
        value: selectedTimezone,
        timezoneData: timezoneDataFixture,
        name: 'user[timezone]',
        ...propsData,
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
    const selectedTz = findTzByName('Alaska');

    beforeEach(async () => {
      await createComponent('Alaska');
    });

    it('renders only the time zone searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe(formatTimezone(selectedTz));
    });

    it('should not display empty results message', () => {
      expect(findEmptyResultsItem().exists()).toBe(false);
    });

    it('updates the dropdown when a new time zone is passed in', async () => {
      const newTimezone = 'Europe/Paris';
      wrapper.setProps({ value: newTimezone });
      await nextTick();
      expect(findDropdown().props('toggleText')).toBe('[UTC+2] Paris');
    });

    describe('Custom events', () => {
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
      expect(findHiddenInput().element.value).toBe('Berlin');
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

  describe('when the value prop is cleared after selection', () => {
    it('resets to the placeholder when no default option is set', async () => {
      await createComponent('', 'Europe/Berlin');
      expect(findDropdown().props('toggleText')).toBe('[UTC+2] Berlin');

      wrapper.setProps({ value: '' });
      await nextTick();

      expect(findDropdown().props('toggleText')).toBe('Select timezone');
    });

    it('resets to the default option when defaultText is set', async () => {
      const defaultText = 'System default';
      await createComponent('', 'Europe/Berlin', { defaultText });
      expect(findDropdown().props('toggleText')).toBe('[UTC+2] Berlin');

      wrapper.setProps({ value: '' });
      await nextTick();

      expect(findDropdown().props('toggleText')).toBe(defaultText);
    });
  });

  describe('when disabled', () => {
    beforeEach(async () => {
      await createComponent('', 'Europe/Berlin', { disabled: true });
    });

    it('disables the listbox', () => {
      expect(findDropdown().props('disabled')).toBe(true);
    });

    it('does not render a submitting input', () => {
      expect(findHiddenInput().exists()).toBe(false);
    });
  });

  describe('with a default option', () => {
    const defaultText = 'System default';

    it('prepends the default option to the list', async () => {
      await createComponent('', '', { defaultText });

      expect(findDropdownItemByIndex(0).text()).toBe(defaultText);
      expect(findAllDropdownItems()).toHaveLength(timezoneDataFixture.length + 1);
    });

    it('hides the default option while searching', async () => {
      await createComponent('Alaska', '', { defaultText });

      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).not.toBe(defaultText);
    });

    it('shows the no results message when a search matches nothing', async () => {
      await createComponent('does not exist', '', { defaultText });

      expect(findEmptyResultsItem().exists()).toBe(true);
    });

    it('submits a blank value when the default option is selected', async () => {
      await createComponent('', 'Europe/Berlin', { defaultText });

      findDropdown().vm.$emit('select', defaultText);
      await nextTick();

      expect(findDropdown().props('toggleText')).toBe(defaultText);
      expect(findHiddenInput().element.value).toBe('');
    });

    it('emits a blank sentinel when the default option is selected', async () => {
      await createComponent('', 'Europe/Berlin', { defaultText });

      findDropdown().vm.$emit('select', defaultText);

      expect(wrapper.emitted('input')).toEqual([[{ formattedTimezone: '', identifier: '' }]]);
    });

    it.each(['', null])('selects the default option when the value is %p', async (value) => {
      await createComponent('', value, { defaultText });

      expect(findDropdown().props('toggleText')).toBe(defaultText);
      expect(findHiddenInput().element.value).toBe('');
    });

    it('preserves an unrecognized initial value instead of clearing it', async () => {
      await createComponent('', 'Berlin', { defaultText });

      expect(findDropdown().props('toggleText')).toBe('Select timezone');
      expect(findHiddenInput().element.value).toBe('Berlin');
    });
  });
});
