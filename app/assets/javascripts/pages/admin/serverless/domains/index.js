import initSettingsPanels from '~/settings_panels';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();

  const domainCard = document.querySelector('.js-domain-cert-show');
  const domainForm = document.querySelector('.js-domain-cert-inputs');
  const domainReplaceButton = document.querySelector('.js-domain-cert-replace-btn');
  const domainSubmitButton = document.querySelector('.js-serverless-domain-submit');

  if (domainReplaceButton && domainCard && domainForm) {
    domainReplaceButton.addEventListener('click', () => {
      domainCard.classList.add('hidden');
      domainForm.classList.remove('hidden');
      domainSubmitButton.removeAttribute('disabled');
    });
  }
});
