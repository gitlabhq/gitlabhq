import initForm from '../form';
import MirrorRepos from '~/mirrors/mirror_repos';

document.addEventListener('DOMContentLoaded', () => {
  initForm();

  const mirrorReposContainer = document.querySelector('.js-mirror-settings');
  if (mirrorReposContainer) new MirrorRepos(mirrorReposContainer).init();
});
