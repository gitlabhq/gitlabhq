import '~/webpack';
import '~/commons';
import {
  initSuperSidebar,
  initSuperSidebarToggle,
  initPageBreadcrumbs,
  getSuperSidebarData,
  initAdvancedSearchModal,
} from '~/super_sidebar/super_sidebar_bundle';

const superSidebarData = getSuperSidebarData();

initSuperSidebar(superSidebarData);
initSuperSidebarToggle();
initPageBreadcrumbs();
initAdvancedSearchModal(superSidebarData);
