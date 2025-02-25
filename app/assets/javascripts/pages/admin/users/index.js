import {
  initAdminUsersFilterApp,
  initAdminUserActions,
  initAdminUsersApp,
  initDeleteUserModals,
} from '~/admin/users';
import initConfirmModal from '~/confirm_modal';
import { initPasswordInput } from '~/authentication/password';

initAdminUsersFilterApp();
initAdminUserActions();
initAdminUsersApp();
initDeleteUserModals();
initConfirmModal();
initPasswordInput();
