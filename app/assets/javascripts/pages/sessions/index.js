import { initPasskeyAuthentication } from '~/authentication/webauthn';
import { mount2faAuthentication } from '~/authentication/mount_2fa';
import { initPasswordInput } from '~/authentication/password';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';

initPasskeyAuthentication();
mount2faAuthentication();
initPasswordInput();

new SigninTabsMemoizer(); // eslint-disable-line no-new
