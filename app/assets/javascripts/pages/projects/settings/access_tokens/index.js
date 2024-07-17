import {
  initAccessTokenTableApp,
  initInactiveAccessTokenTableApp,
  initExpiresAtField,
  initNewAccessTokenApp,
} from '~/access_tokens';

initAccessTokenTableApp();
initExpiresAtField();
initNewAccessTokenApp();

if (gon.features.retainResourceAccessTokenUserAfterRevoke) {
  initInactiveAccessTokenTableApp();
}
