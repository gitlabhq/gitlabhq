import Tracking from '~/tracking';

function assembleDesignPayload(payloadArr) {
  return {
    value: {
      'internal-object-refrerer': payloadArr[0],
      'design-collection-owner': payloadArr[1],
      'design-version-number': payloadArr[2],
      'design-is-current-version': payloadArr[3],
    },
  };
}

// Tracking Constants
const DESIGN_TRACKING_PAGE_NAME = 'projects:issues:design';

// eslint-disable-next-line import/prefer-default-export
export function trackDesignDetailView(
  referer = '',
  owner = '',
  designVersion = 1,
  latestVersion = false,
) {
  Tracking.event(DESIGN_TRACKING_PAGE_NAME, 'design_viewed', {
    label: 'design_viewed',
    ...assembleDesignPayload([referer, owner, designVersion, latestVersion]),
  });
}
