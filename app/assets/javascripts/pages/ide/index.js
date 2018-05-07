import { initIde, resetServiceWorkersPublicPath } from '~/ide/index';

document.addEventListener('DOMContentLoaded', () => {
  const ideElement = document.getElementById('ide');
  if (ideElement) {
    resetServiceWorkersPublicPath();
    initIde(ideElement);
  }
});
