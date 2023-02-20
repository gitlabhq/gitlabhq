import { snakeCase } from 'lodash';
import { handleTracking } from '~/ide/lib/gitlab_web_ide/handle_tracking_event';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { mockTracking } from 'helpers/tracking_helper';

describe('ide/handle_tracking_event', () => {
  let trackingSpy;

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  describe('when the event does not contain data', () => {
    it('does not send extra property to snowplow', () => {
      const event = { name: 'event-name' };

      handleTracking(event);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, snakeCase(event.name));
    });
  });

  describe('when the event contains data', () => {
    it('sends extra property to snowplow', () => {
      const event = { name: 'event-name', data: { 'extra-details': 'details' } };

      handleTracking(event);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, snakeCase(event.name), {
        extra: convertObjectPropsToSnakeCase(event.data),
      });
    });
  });
});
