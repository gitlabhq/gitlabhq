import projectSelect from '~/project_select';
import initLegacyFilters from '~/init_legacy_filters';

document.addEventListener('DOMContentLoaded', () => {
  projectSelect();
  initLegacyFilters();
});
