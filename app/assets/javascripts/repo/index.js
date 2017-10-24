import $ from 'jquery';
import Vue from 'vue';
import Terminal from 'vendor/xterm/xterm';
import 'vendor/xterm/encoding-indexes';
import 'vendor/xterm/encoding';
import 'vendor/xterm/fit';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import Service from './services/repo_service';
import IDEService from './services/ide_service';
import Store from './stores/repo_store';
import Repo from './components/repo.vue';
import RepoEditButton from './components/repo_edit_button.vue';
import Translate from '../vue_shared/translate';
import '../terminal/terminal';

window.Terminal = Terminal;

function initDropdowns() {
  $('.js-tree-ref-target-holder').hide();
}

function addEventsForNonVueEls() {
  window.onbeforeunload = function confirmUnload(e) {
    const hasChanged = Store.openedFiles
      .some(file => file.changed);
    if (!hasChanged) return undefined;
    const event = e || window.event;
    if (event) event.returnValue = 'Are you sure you want to lose unsaved changes?';
    // For Safari
    return 'Are you sure you want to lose unsaved changes?';
  };
}

function setInitialStore(data) {
  const isIde = data.isIde === 'true';

  Store.service = isIde ? IDEService : Service;
  Store.terminalEndpoint = data.terminalUrl;
  Store.service.url = data.url;
  Store.service.refsUrl = data.refsUrl;
  Store.projectId = data.projectId;
  Store.projectName = data.projectName;
  Store.projectUrl = data.projectUrl;
  Store.canCommit = data.canCommit;
  Store.onTopOfBranch = data.onTopOfBranch;
  Store.newMrTemplateUrl = decodeURIComponent(data.newMrTemplateUrl);
  Store.customBranchURL = decodeURIComponent(data.blobUrl);
  Store.isRoot = convertPermissionToBoolean(data.root);
  Store.isInitialRoot = convertPermissionToBoolean(data.root);
  Store.currentBranch = $('button.dropdown-menu-toggle').attr('data-ref');

  if (!isIde) {
    Store.checkIsCommitable();
    Store.setBranchHash();
  }
}

function initRepo(el) {
  return new Vue({
    el,
    components: {
      repo: Repo,
    },
    render(createElement) {
      return createElement('repo');
    },
  });
}

function initRepoEditButton(el) {
  return new Vue({
    el,
    components: {
      repoEditButton: RepoEditButton,
    },
  });
}

function initRepoBundle() {
  const repo = document.getElementById('repo');
  const editButton = document.querySelector('.editable-mode');
  setInitialStore(repo.dataset);
  addEventsForNonVueEls();
  initDropdowns();

  Vue.use(Translate);

  initRepo(repo);
  initRepoEditButton(editButton);
}

$(initRepoBundle);

export default initRepoBundle;
