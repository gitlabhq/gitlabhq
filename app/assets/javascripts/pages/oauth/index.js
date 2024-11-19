import initSearchSettings from '~/search_settings';
import initAccordion from '~/accordion';

initSearchSettings();
document.querySelectorAll('.js-experimental-setting-accordion').forEach(initAccordion);
