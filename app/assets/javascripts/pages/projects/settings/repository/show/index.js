import initForm from '../form';
import PushPull from './push_pull';

document.addEventListener('DOMContentLoaded', () => {
  initForm();

  const pushPullContainer = document.querySelector('.js-mirror-settings');
  if (pushPullContainer) new PushPull(pushPullContainer).init();
});
