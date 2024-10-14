import * as utils from '~/contributors/utils';

describe('Contributors Util Functions', () => {
  describe('xAxisLabelFormatter', () => {
    it('should return year if the date is in January', () => {
      expect(utils.xAxisLabelFormatter(new Date('01-12-2019'))).toEqual('2019');
    });

    it('should return month name otherwise', () => {
      expect(utils.xAxisLabelFormatter(new Date('12-02-2019'))).toEqual('Dec');
      expect(utils.xAxisLabelFormatter(new Date('07-12-2019'))).toEqual('Jul');
    });
  });
});
