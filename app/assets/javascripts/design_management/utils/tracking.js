import Tracking from '~/tracking';

function assembleDesignPayload(payloadArr) {
  return {
    value: {
      'internal-object-refrerer': payloadArr[0],
      'version-number': payloadArr[1],
      'current-version': payloadArr[2],
    },
  };
}

// Tracking Constants
const DESIGN_TRACKING_PAGE_NAME = 'projects:issues:design';

// eslint-disable-next-line import/prefer-default-export
export function trackDesignDetailView(refrerer = '', designVersion = 1, latestVersion = false) {
  Tracking.event(DESIGN_TRACKING_PAGE_NAME, 'design_viewed', {
    label: 'design_viewed',
    ...assembleDesignPayload([refrerer, designVersion, latestVersion]),
  });
}
