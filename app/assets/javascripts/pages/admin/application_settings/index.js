import initSettingsPanels from '~/settings_panels';
import projectSelect from '~/project_select';
import UsagePingPayload from './usage_ping_payload';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();
  projectSelect();
  new UsagePingPayload(
    document.querySelector('.js-usage-ping-payload-trigger'),
    document.querySelector('.js-usage-ping-payload'),
  ).init();
});
