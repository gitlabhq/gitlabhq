import $ from 'jquery';
import TimezoneDropdown, {
  formatUtcOffset,
  formatTimezone,
  findTimezoneByIdentifier,
} from '~/pages/projects/pipeline_schedules/shared/components/timezone_dropdown';

describe('Timezone Dropdown', () => {
  let $inputEl = null;
  let $dropdownEl = null;
  let $wrapper = null;
  const tzListSel = '.dropdown-content ul li a.is-active';
  const tzDropdownToggleText = '.dropdown-toggle-text';

  describe('Initialize', () => {
    describe('with dropdown already loaded', () => {
      beforeEach(() => {
        loadFixtures('pipeline_schedules/edit.html');
        $wrapper = $('.dropdown');
        $inputEl = $('#schedule_cron_timezone');
        $dropdownEl = $('.js-timezone-dropdown');

        // eslint-disable-next-line no-new
        new TimezoneDropdown({
          $inputEl,
          $dropdownEl,
        });
      });

      it('can take an $inputEl in the constructor', () => {
        const tzStr = '[UTC + 5.5] Sri Jayawardenepura';
        const tzValue = 'Asia/Colombo';

        expect($inputEl.val()).toBe('UTC');

        $(`${tzListSel}:contains('${tzStr}')`, $wrapper).trigger('click');

        const val = $inputEl.val();

        expect(val).toBe(tzValue);
        expect(val).not.toBe('UTC');
      });

      it('will format data array of timezones into a list of offsets', () => {
        const data = $dropdownEl.data('data');
        const formatted = $wrapper.find(tzListSel).text();

        data.forEach((item) => {
          expect(formatted).toContain(formatTimezone(item));
        });
      });

      it('will default the timezone to UTC', () => {
        const tz = $inputEl.val();

        expect(tz).toBe('UTC');
      });
    });

    describe('without dropdown loaded', () => {
      beforeEach(() => {
        loadFixtures('pipeline_schedules/edit.html');
        $wrapper = $('.dropdown');
        $inputEl = $('#schedule_cron_timezone');
        $dropdownEl = $('.js-timezone-dropdown');
      });

      it('will populate the list of UTC offsets after the dropdown is loaded', () => {
        expect($wrapper.find(tzListSel).length).toEqual(0);

        // eslint-disable-next-line no-new
        new TimezoneDropdown({
          $inputEl,
          $dropdownEl,
        });

        expect($wrapper.find(tzListSel).length).toEqual($($dropdownEl).data('data').length);
      });

      it('will call a provided handler when a new timezone is selected', () => {
        const onSelectTimezone = jest.fn();
        // eslint-disable-next-line no-new
        new TimezoneDropdown({
          $inputEl,
          $dropdownEl,
          onSelectTimezone,
        });

        $wrapper.find(tzListSel).first().trigger('click');

        expect(onSelectTimezone).toHaveBeenCalled();
      });

      it('will correctly set the dropdown label if a timezone identifier is set on the inputEl', () => {
        $inputEl.val('America/St_Johns');

        // eslint-disable-next-line no-new
        new TimezoneDropdown({
          $inputEl,
          $dropdownEl,
          displayFormat: (selectedItem) => formatTimezone(selectedItem),
        });

        expect($wrapper.find(tzDropdownToggleText).html()).toEqual('[UTC - 2.5] Newfoundland');
      });

      it('will call a provided `displayFormat` handler to format the dropdown value', () => {
        const displayFormat = jest.fn();
        // eslint-disable-next-line no-new
        new TimezoneDropdown({
          $inputEl,
          $dropdownEl,
          displayFormat,
        });

        $wrapper.find(tzListSel).first().trigger('click');

        expect(displayFormat).toHaveBeenCalled();
      });
    });
  });

  describe('formatUtcOffset', () => {
    it('will convert negative utc offsets in seconds to hours and minutes', () => {
      expect(formatUtcOffset(-21600)).toEqual('- 6');
    });

    it('will convert positive utc offsets in seconds to hours and minutes', () => {
      expect(formatUtcOffset(25200)).toEqual('+ 7');
      expect(formatUtcOffset(49500)).toEqual('+ 13.75');
    });

    it('will return 0 when given a string', () => {
      expect(formatUtcOffset('BLAH')).toEqual('0');
      expect(formatUtcOffset('$%$%')).toEqual('0');
    });

    it('will return 0 when given an array', () => {
      expect(formatUtcOffset(['an', 'array'])).toEqual('0');
    });

    it('will return 0 when given an object', () => {
      expect(formatUtcOffset({ some: '', object: '' })).toEqual('0');
    });

    it('will return 0 when given null', () => {
      expect(formatUtcOffset(null)).toEqual('0');
    });

    it('will return 0 when given undefined', () => {
      expect(formatUtcOffset(undefined)).toEqual('0');
    });

    it('will return 0 when given empty input', () => {
      expect(formatUtcOffset('')).toEqual('0');
    });
  });

  describe('formatTimezone', () => {
    it('given name: "Chatham Is.", offset: "49500", will format for display as "[UTC + 13.75] Chatham Is."', () => {
      expect(
        formatTimezone({
          name: 'Chatham Is.',
          offset: 49500,
          identifier: 'Pacific/Chatham',
        }),
      ).toEqual('[UTC + 13.75] Chatham Is.');
    });

    it('given name: "Saskatchewan", offset: "-21600", will format for display as "[UTC - 6] Saskatchewan"', () => {
      expect(
        formatTimezone({
          name: 'Saskatchewan',
          offset: -21600,
          identifier: 'America/Regina',
        }),
      ).toEqual('[UTC - 6] Saskatchewan');
    });

    it('given name: "Accra", offset: "0", will format for display as "[UTC 0] Accra"', () => {
      expect(
        formatTimezone({
          name: 'Accra',
          offset: 0,
          identifier: 'Africa/Accra',
        }),
      ).toEqual('[UTC 0] Accra');
    });
  });

  describe('findTimezoneByIdentifier', () => {
    const tzList = [
      {
        identifier: 'Asia/Tokyo',
        name: 'Sapporo',
        offset: 32400,
      },
      {
        identifier: 'Asia/Hong_Kong',
        name: 'Hong Kong',
        offset: 28800,
      },
      {
        identifier: 'Asia/Dhaka',
        name: 'Dhaka',
        offset: 21600,
      },
    ];

    const identifier = 'Asia/Dhaka';
    it('returns the correct object if the identifier exists', () => {
      const res = findTimezoneByIdentifier(tzList, identifier);

      expect(res).toBeTruthy();
      expect(res).toBe(tzList[2]);
    });

    it('returns null if it doesnt find the identifier', () => {
      const res = findTimezoneByIdentifier(tzList, 'Australia/Melbourne');

      expect(res).toBeNull();
    });

    it('returns null if there is no identifier given', () => {
      expect(findTimezoneByIdentifier(tzList)).toBeNull();
      expect(findTimezoneByIdentifier(tzList, '')).toBeNull();
    });

    it('returns null if there is an empty or invalid array given', () => {
      expect(findTimezoneByIdentifier([], identifier)).toBeNull();
      expect(findTimezoneByIdentifier(null, identifier)).toBeNull();
      expect(findTimezoneByIdentifier(undefined, identifier)).toBeNull();
    });
  });
});
