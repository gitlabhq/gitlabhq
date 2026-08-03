import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import CommitOptionsDropdown from './components/commit_options_dropdown.vue';

export default function initCommitOptionsDropdown() {
  const el = document.querySelector('#js-commit-options-dropdown');

  if (!el) {
    return false;
  }

  const {
    newProjectTagPath,
    emailPatchesPath,
    plainDiffPath,
    canRevert,
    canCherryPick,
    canTag,
    canEmailPatches,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'CommitOptionsDropdownRoot',
    provide: { newProjectTagPath, emailPatchesPath, plainDiffPath },
    component: CommitOptionsDropdown,
    props: {
      canRevert: parseBoolean(canRevert),
      canCherryPick: parseBoolean(canCherryPick),
      canTag: parseBoolean(canTag),
      canEmailPatches: parseBoolean(canEmailPatches),
    },
  });
}
