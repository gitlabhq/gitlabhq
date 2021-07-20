import { initExpiresAtField } from '~/access_tokens';
import { initAdminUserActions, initDeleteUserModals } from '~/admin/users';
import initConfirmModal from '~/confirm_modal';

initAdminUserActions();
initDeleteUserModals();
initExpiresAtField();
initConfirmModal();
