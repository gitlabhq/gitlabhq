import {
  initAdminUserActions,
  initAdminUsersApp,
  initAdminUsersFilterApp,
  initDeleteUserModals,
  initRemoveFromOrganizationModal,
} from '~/admin/users';
import initConfirmModal from '~/confirm_modal';
import { initPasswordInput } from '~/authentication/password';

initAdminUsersFilterApp();
initAdminUserActions();
initAdminUsersApp();
initRemoveFromOrganizationModal();
initDeleteUserModals();
initConfirmModal();
initPasswordInput();
