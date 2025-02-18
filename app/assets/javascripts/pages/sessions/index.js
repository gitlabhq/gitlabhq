import { mount2faAuthentication } from '~/authentication/mount_2fa';
import { initPasswordInput } from '~/authentication/password';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';

mount2faAuthentication();
initPasswordInput();

new SigninTabsMemoizer(); // eslint-disable-line no-new
