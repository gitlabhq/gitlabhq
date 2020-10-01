import { parseUserIds, stringifyUserIds } from '~/user_lists/store/utils';

describe('User List Store Utils', () => {
  describe('parseUserIds', () => {
    it('should split comma-seperated user IDs into an array', () => {
      expect(parseUserIds('1,2,3')).toEqual(['1', '2', '3']);
    });

    it('should filter whitespace before the comma', () => {
      expect(parseUserIds('1\t,2     ,3')).toEqual(['1', '2', '3']);
    });

    it('should filter whitespace after the comma', () => {
      expect(parseUserIds('1,\t2,    3')).toEqual(['1', '2', '3']);
    });
  });

  describe('stringifyUserIds', () => {
    it('should convert a list of user IDs into a comma-separated string', () => {
      expect(stringifyUserIds(['1', '2', '3'])).toBe('1,2,3');
    });
  });
});
