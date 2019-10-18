import * as errorTrackingUtils from '~/error_tracking/utils';

const externalUrl = 'https://sentry.io/organizations/test-sentry-nk/issues/1/?project=1';

describe('Error Tracking Events', () => {
  describe('trackViewInSentryOptions', () => {
    it('should return correct event options', () => {
      expect(errorTrackingUtils.trackViewInSentryOptions(externalUrl)).toEqual({
        category: 'Error Tracking',
        action: 'click_view_in_sentry',
        label: 'External Url',
        property: externalUrl,
      });
    });
  });

  describe('trackClickErrorLinkToSentryOptions', () => {
    it('should return correct event options', () => {
      expect(errorTrackingUtils.trackClickErrorLinkToSentryOptions(externalUrl)).toEqual({
        category: 'Error Tracking',
        action: 'click_error_link_to_sentry',
        label: 'Error Link',
        property: externalUrl,
      });
    });
  });
});
