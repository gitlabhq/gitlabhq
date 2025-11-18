import initSettingsPanels from '~/settings_panels';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import SearchBox from './search_box.vue';

document.addEventListener('DOMContentLoaded', () => {
  initSettingsPanels();
  initSimpleApp('#js-o11y-service-settings-search', SearchBox, {
    name: 'O11yServiceSettingsSearch',
  });
});
