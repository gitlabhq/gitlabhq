import { getParsedDataset } from '~/pages/admin/application_settings/utils';
import { rawMockData, mockData } from './mock_data';

describe('utils', () => {
  describe('getParsedDataset', () => {
    it('returns correct results', () => {
      expect(
        getParsedDataset({
          dataset: rawMockData,
          booleanAttributes: [
            'signupEnabled',
            'requireAdminApprovalAfterUserSignup',
            'domainDenylistEnabled',
            'denylistTypeRawSelected',
            'emailRestrictionsEnabled',
            'passwordNumberRequired',
            'passwordLowercaseRequired',
            'passwordUppercaseRequired',
            'passwordSymbolRequired',
            'promotionManagementAvailable',
            'enableMemberPromotionManagement',
          ],
        }),
      ).toEqual(mockData);
    });
  });
});
