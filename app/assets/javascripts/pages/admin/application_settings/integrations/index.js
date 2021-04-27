import initIntegrationsList from '~/integrations/index';
import PersistentUserCallout from '~/persistent_user_callout';

const callout = document.querySelector('.js-admin-integrations-moved');

PersistentUserCallout.factory(callout);

initIntegrationsList();
