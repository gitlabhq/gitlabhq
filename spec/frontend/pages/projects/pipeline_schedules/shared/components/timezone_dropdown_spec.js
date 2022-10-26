import { formatUtcOffset, formatTimezone } from '~/lib/utils/datetime_utility';
import { findTimezoneByIdentifier } from '~/pages/projects/pipeline_schedules/shared/components/timezone_dropdown';

describe('Timezone Dropdown', () => {
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
