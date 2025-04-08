import { parseFormProps } from '~/admin/application_settings/deletion_protection/utils';
import { parseBoolean } from '~/lib/utils/common_utils';

describe('deletion protection utils', () => {
  describe('parseFormProps', () => {
    const input = {
      deletionAdjournedPeriod: '7',
      delayedGroupDeletion: 'true',
      delayedProjectDeletion: 'false',
    };

    it('returns the expected result', () => {
      expect(parseFormProps(input)).toStrictEqual({
        deletionAdjournedPeriod: parseInt(input.deletionAdjournedPeriod, 10),
        delayedGroupDeletion: parseBoolean(input.delayedGroupDeletion),
        delayedProjectDeletion: parseBoolean(input.delayedProjectDeletion),
      });
    });

    it('does not attempt to parse an undefined adjourned period', () => {
      expect(parseFormProps({ deletionAdjournedPeriod: undefined })).toMatchObject({
        deletionAdjournedPeriod: undefined,
      });
    });
  });
});
