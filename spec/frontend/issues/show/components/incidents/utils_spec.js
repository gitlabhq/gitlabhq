import timezoneMock from 'timezone-mock';
import {
  displayAndLogError,
  getEventIcon,
  getUtcShiftedDateNow,
} from '~/issues/show/components/incidents/utils';
import { createAlert } from '~/flash';

jest.mock('~/flash');

describe('incident utils', () => {
  describe('display and log error', () => {
    it('displays and logs an error', () => {
      const error = new Error('test');
      displayAndLogError(error);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching incident timeline events.',
        captureError: true,
        error,
      });
    });
  });

  describe('get event icon', () => {
    it('should display a matching event icon name', () => {
      ['comment', 'issues', 'status'].forEach((name) => {
        expect(getEventIcon(name)).toBe(name);
      });
    });

    it('should return a default icon name', () => {
      expect(getEventIcon('non-existent-icon-name')).toBe('comment');
    });
  });

  describe('getUtcShiftedDateNow', () => {
    beforeEach(() => {
      timezoneMock.register('US/Pacific');
    });

    afterEach(() => {
      timezoneMock.unregister();
    });

    it('should shift the date by the timezone offset', () => {
      const date = new Date();

      const shiftedDate = getUtcShiftedDateNow();

      expect(shiftedDate > date).toBe(true);
    });
  });
});
