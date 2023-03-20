import timezoneMock from 'timezone-mock';
import {
  displayAndLogError,
  getEventIcon,
  getUtcShiftedDate,
  getPreviousEventTags,
} from '~/issues/show/components/incidents/utils';
import { createAlert } from '~/alert';
import { mockTimelineEventTags } from './mock_data';

jest.mock('~/alert');

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
      ['comment', 'issues', 'label', 'status'].forEach((name) => {
        expect(getEventIcon(name)).toBe(name);
      });
    });

    it('should return a default icon name', () => {
      expect(getEventIcon('non-existent-icon-name')).toBe('comment');
    });
  });

  describe('getUtcShiftedDate', () => {
    beforeEach(() => {
      timezoneMock.register('US/Pacific');
    });

    afterEach(() => {
      timezoneMock.unregister();
    });

    it('should shift the date by the timezone offset', () => {
      const date = new Date();

      const shiftedDate = getUtcShiftedDate();

      expect(shiftedDate > date).toBe(true);
    });
  });

  describe('getPreviousEventTags', () => {
    it('should return an empty array, when passed object contains no tags', () => {
      const nodes = [];
      const previousTags = getPreviousEventTags(nodes);

      expect(previousTags.length).toBe(0);
    });

    it('should return an array of strings, when passed object containing tags', () => {
      const previousTags = getPreviousEventTags(mockTimelineEventTags.nodes);
      expect(previousTags.length).toBe(2);
      expect(previousTags).toContain(mockTimelineEventTags.nodes[0].name);
      expect(previousTags).toContain(mockTimelineEventTags.nodes[1].name);
    });
  });
});
