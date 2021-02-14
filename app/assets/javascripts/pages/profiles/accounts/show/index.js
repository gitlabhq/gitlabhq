import { initClose2faSuccessMessage } from '~/authentication/two_factor_auth';
import initProfileAccount from '~/profile/account';

document.addEventListener('DOMContentLoaded', initProfileAccount);

initClose2faSuccessMessage();
