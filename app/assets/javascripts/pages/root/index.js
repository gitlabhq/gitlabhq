// if the "projects dashboard" is a user's default dashboard, when they visit the
// instance root index, the dashboard will be served by the root controller instead
// of a dashboard controller. The root index redirects for all other default dashboards.
import '../dashboard/projects/index';

// With the new `personal_homepage` feature flag enabled, the root_url now renders a different page.
// We can keep above import for now. It is still required for when the feature flag is disabled for
// a user.
import initHomepage from '~/homepage/index';

initHomepage();
