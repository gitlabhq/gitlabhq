import '~/webpack';
import '~/commons';
import {
  initSuperSidebar,
  initSuperSidebarToggle,
  initPageBreadcrumbs,
  getSuperSidebarData,
  initSuperTopbar,
} from '~/super_sidebar/super_sidebar_bundle';

const superSidebarData = getSuperSidebarData();

initSuperSidebar(superSidebarData);
initSuperSidebarToggle();
initSuperTopbar(superSidebarData);
initPageBreadcrumbs();
