import MirrorRepos from '~/mirrors/mirror_repos';
import initForm from '../form';

initForm();

const mirrorReposContainer = document.querySelector('.js-mirror-settings');
if (mirrorReposContainer) new MirrorRepos(mirrorReposContainer).init();
