import '~/webpack';
import '~/commons';
import {
  initSuperSidebar,
  initPageBreadcrumbs,
  getSuperSidebarData,
  initSuperTopbar,
} from '~/super_sidebar/super_sidebar_bundle';

const superSidebarData = getSuperSidebarData();

initSuperSidebar(superSidebarData);
initSuperTopbar(superSidebarData);
initPageBreadcrumbs();
