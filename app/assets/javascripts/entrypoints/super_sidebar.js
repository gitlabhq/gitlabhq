import '~/webpack';
import '~/commons';
import {
  initSuperSidebar,
  initSuperSidebarToggle,
  initPageBreadcrumbs,
  getSuperSidebarData,
} from '~/super_sidebar/super_sidebar_bundle';

const superSidebarData = getSuperSidebarData();

initSuperSidebar(superSidebarData);
initSuperSidebarToggle();
initPageBreadcrumbs();
