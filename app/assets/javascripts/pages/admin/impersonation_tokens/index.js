import {
  initAccessTokenTableApp,
  initExpiresAtField,
  initNewAccessTokenApp,
} from '~/access_tokens';
import { initAdminUserActions, initDeleteUserModals } from '~/admin/users';
import initConfirmModal from '~/confirm_modal';

initAccessTokenTableApp();
initExpiresAtField();
initNewAccessTokenApp();
initAdminUserActions();
initDeleteUserModals();
initConfirmModal();
