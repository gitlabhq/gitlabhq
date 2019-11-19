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

  describe('dateFormatter', () => {
    it('should format provided date to YYYY-MM-DD format', () => {
      expect(utils.dateFormatter(new Date('December 17, 1995 03:24:00'))).toEqual('1995-12-17');
      expect(utils.dateFormatter(new Date(1565308800000))).toEqual('2019-08-09');
    });
  });
});
