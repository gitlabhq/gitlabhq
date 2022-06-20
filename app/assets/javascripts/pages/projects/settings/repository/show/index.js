import MirrorRepos from '~/mirrors/mirror_repos';
import mountBranchRules from '~/projects/settings/repository/branch_rules/mount_branch_rules';
import initForm from '../form';

initForm();

const mirrorReposContainer = document.querySelector('.js-mirror-settings');
if (mirrorReposContainer) new MirrorRepos(mirrorReposContainer).init();

mountBranchRules(document.getElementById('js-branch-rules'));
