import initProfileAccount from '~/profile/account';
import { initClose2faSuccessMessage } from '~/authentication/two_factor_auth';

document.addEventListener('DOMContentLoaded', initProfileAccount);

initClose2faSuccessMessage();
