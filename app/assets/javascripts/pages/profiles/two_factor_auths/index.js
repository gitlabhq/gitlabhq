import $ from 'jquery';
import U2FRegister from '~/u2f/register';

document.addEventListener('DOMContentLoaded', () => {
  const twoFactorNode = document.querySelector('.js-two-factor-auth');
  const skippable = twoFactorNode.dataset.twoFactorSkippable === 'true';
  if (skippable) {
    const button = `<a class="btn btn-sm btn-warning float-right" data-method="patch" href="${twoFactorNode.dataset.two_factor_skip_url}">Configure it later</a>`;
    const flashAlert = document.querySelector('.flash-alert .container-fluid');
    if (flashAlert) flashAlert.insertAdjacentHTML('beforeend', button);
  }

  const u2fRegister = new U2FRegister($('#js-register-u2f'), gon.u2f);
  u2fRegister.start();
});
