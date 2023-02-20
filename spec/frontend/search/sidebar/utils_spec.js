import { convertFiltersData } from '~/search/sidebar/utils';
import { TEST_RAW_BUCKETS, TEST_FILTER_DATA } from '../mock_data';

describe('Global Search sidebar utils', () => {
  describe('convertFiltersData', () => {
    it('converts raw buckets to array', () => {
      expect(convertFiltersData(TEST_RAW_BUCKETS)).toStrictEqual(TEST_FILTER_DATA);
    });
  });
});
