import initSearchSettings from '~/search_settings';
import initWebhookForm, { initHookTestDropdowns } from '~/webhooks';
import { initPushEventsEditForm } from '~/webhooks/webhook';

initSearchSettings();
initWebhookForm();
initPushEventsEditForm();
initHookTestDropdowns();
