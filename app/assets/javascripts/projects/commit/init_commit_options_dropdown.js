import Vue from 'vue';
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

  return new Vue({
    el,
    provide: { newProjectTagPath, emailPatchesPath, plainDiffPath },
    render: (createElement) =>
      createElement(CommitOptionsDropdown, {
        props: {
          canRevert: parseBoolean(canRevert),
          canCherryPick: parseBoolean(canCherryPick),
          canTag: parseBoolean(canTag),
          canEmailPatches: parseBoolean(canEmailPatches),
        },
      }),
  });
}
