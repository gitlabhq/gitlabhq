import initApplicationDeleteButtons from '~/admin/applications';
import { initOAuthApplicationSecret } from '~/oauth_application';
import { initWebIdeOAuthApplicationCallout } from '~/ide/oauth_application_callout';

initApplicationDeleteButtons();
initOAuthApplicationSecret();
initWebIdeOAuthApplicationCallout();
