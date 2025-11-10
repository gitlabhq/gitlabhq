import '~/webpack';
import '~/commons';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  initSuperSidebar,
  initSuperSidebarToggle,
  initPageBreadcrumbs,
  getSuperSidebarData,
  initSuperTopbar,
} from '~/super_sidebar/super_sidebar_bundle';

const superSidebarData = getSuperSidebarData();
const projectStudioAvailable = parseBoolean(document.body.dataset.projectStudioAvailable);
const projectStudioEnabled = parseBoolean(document.body.dataset.projectStudioEnabled);

// The `showDapWelcomeModal` determines whether to show DAP intro banner to new
// users or not. We only set it if project studio is both available and enabled
// for current user and banner was never shown to this user (i.e. missing key)
// Once user dismisses this modal, key is set to `false` and banner is not shown in future.
if (
  projectStudioAvailable &&
  projectStudioEnabled &&
  localStorage.getItem('showDapWelcomeModal') === null
) {
  localStorage.setItem('showDapWelcomeModal', 'true');
}

initSuperSidebar(superSidebarData);
initSuperSidebarToggle();
initSuperTopbar(superSidebarData);
initPageBreadcrumbs();
