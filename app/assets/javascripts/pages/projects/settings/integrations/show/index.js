import initIntegrationsList from '~/integrations/index';
import PersistentUserCallout from '~/persistent_user_callout';

const callout = document.querySelector('.js-webhooks-moved-alert');
PersistentUserCallout.factory(callout);

initIntegrationsList();
