import MirrorPull from './mirror_pull';

document.addEventListener('DOMContentLoaded', () => {
  const mirrorPull = new MirrorPull('.js-project-mirror-push-form');
  mirrorPull.init();
});
