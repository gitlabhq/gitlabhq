import { mockTracking } from 'helpers/tracking_helper';
import { trackDesignDetailView } from '~/design_management/utils/tracking';

function getTrackingSpy(key) {
  return mockTracking(key, undefined, jest.spyOn);
}

describe('Tracking Events', () => {
  describe('trackDesignDetailView', () => {
    const eventKey = 'projects:issues:design';
    const eventName = 'view_design';

    it('trackDesignDetailView fires a tracking event when called', () => {
      const trackingSpy = getTrackingSpy(eventKey);

      trackDesignDetailView();

      expect(trackingSpy).toHaveBeenCalledWith(
        eventKey,
        eventName,
        expect.objectContaining({
          label: eventName,
          context: {
            schema: expect.any(String),
            data: {
              'design-version-number': 1,
              'design-is-current-version': false,
              'internal-object-referrer': '',
              'design-collection-owner': '',
            },
          },
        }),
      );
    });

    it('trackDesignDetailView allows to customize the value payload', () => {
      const trackingSpy = getTrackingSpy(eventKey);

      trackDesignDetailView('from-a-test', 'test', 100, true);

      expect(trackingSpy).toHaveBeenCalledWith(
        eventKey,
        eventName,
        expect.objectContaining({
          label: eventName,
          context: {
            schema: expect.any(String),
            data: {
              'design-version-number': 100,
              'design-is-current-version': true,
              'internal-object-referrer': 'from-a-test',
              'design-collection-owner': 'test',
            },
          },
        }),
      );
    });
  });
});
