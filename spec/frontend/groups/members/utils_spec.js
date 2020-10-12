import { membersJsonString, membersParsed } from './mock_data';
import { parseDataAttributes } from '~/groups/members/utils';

describe('group member utils', () => {
  describe('parseDataAttributes', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
      el.setAttribute('data-members', membersJsonString);
      el.setAttribute('data-group-id', '234');
    });

    afterEach(() => {
      el = null;
    });

    it('correctly parses the data attributes', () => {
      expect(parseDataAttributes(el)).toEqual({
        members: membersParsed,
        sourceId: 234,
      });
    });
  });
});
