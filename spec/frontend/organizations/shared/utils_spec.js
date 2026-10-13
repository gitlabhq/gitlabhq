import { timestampType, isDefaultOrganization } from '~/organizations/shared/utils';
import { SORT_CREATED_AT, SORT_UPDATED_AT, SORT_NAME } from '~/organizations/shared/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { mockDefaultOrganization } from './mock_data';

jest.mock('~/vue_shared/plugins/global_toast');

describe('isDefaultOrganization', () => {
  it('returns true for the default organization', () => {
    expect(isDefaultOrganization(mockDefaultOrganization)).toBe(true);
  });

  it('returns false for a non-default organization', () => {
    expect(isDefaultOrganization({ id: 'gid://gitlab/Organizations::Organization/999' })).toBe(
      false,
    );
  });
});

describe('timestampType', () => {
  describe.each`
    sortName           | expectedTimestampType
    ${SORT_CREATED_AT} | ${TIMESTAMP_TYPE_CREATED_AT}
    ${SORT_UPDATED_AT} | ${TIMESTAMP_TYPE_UPDATED_AT}
    ${SORT_NAME}       | ${TIMESTAMP_TYPE_CREATED_AT}
  `('when sort name is $sortName', ({ sortName, expectedTimestampType }) => {
    it(`returns ${expectedTimestampType}`, () => {
      expect(timestampType(sortName)).toBe(expectedTimestampType);
    });
  });
});
