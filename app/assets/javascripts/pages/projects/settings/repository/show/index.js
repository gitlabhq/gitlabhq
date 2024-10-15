import 'vendor/bootstrap/js/src/collapse';
import MirrorRepos from '~/mirrors/mirror_repos';
import mountBranchRules from '~/projects/settings/repository/branch_rules/mount_branch_rules';
import mountDefaultBranchSelector from '~/projects/settings/mount_default_branch_selector';
import mountRepositoryMaintenance from '~/projects/settings/repository/maintenance/mount_repository_maintenance';

import initForm from '../form';

initForm();

const mirrorReposContainer = document.querySelector('.js-mirror-settings');
if (mirrorReposContainer) new MirrorRepos(mirrorReposContainer).init();

mountBranchRules(document.getElementById('js-branch-rules'));
mountDefaultBranchSelector(document.querySelector('.js-select-default-branch'));
mountRepositoryMaintenance();
