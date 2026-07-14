import '~/webpack';
import '~/commons';
// Configure the JS path helpers with the relative URL root before any sidebar
// component renders. Otherwise helpers like `destroyUserSessionPath()` emit
// paths without the root (e.g. `/users/sign_out` instead of
// `/relative/users/sign_out`) on relative URL installations. Unlike `main.js`,
// this entrypoint does not import `~/behaviors`, where this is configured.
import '~/behaviors/configure_path_helpers';
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
