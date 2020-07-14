import Tracking from '~/tracking';

// Tracking Constants
const DESIGN_TRACKING_CONTEXT_SCHEMA = 'iglu:com.gitlab/design_management_context/jsonschema/1-0-0';
const DESIGN_TRACKING_PAGE_NAME = 'projects:issues:design';
const DESIGN_TRACKING_EVENT_NAME = 'view_design';

// eslint-disable-next-line import/prefer-default-export
export function trackDesignDetailView(
  referer = '',
  owner = '',
  designVersion = 1,
  latestVersion = false,
) {
  Tracking.event(DESIGN_TRACKING_PAGE_NAME, DESIGN_TRACKING_EVENT_NAME, {
    label: DESIGN_TRACKING_EVENT_NAME,
    context: {
      schema: DESIGN_TRACKING_CONTEXT_SCHEMA,
      data: {
        'design-version-number': designVersion,
        'design-is-current-version': latestVersion,
        'internal-object-referrer': referer,
        'design-collection-owner': owner,
      },
    },
  });
}
