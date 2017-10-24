import $ from 'jquery';
import Vue from 'vue';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import Service from './services/repo_service';
import Store from './stores/repo_store';
import Repo from './components/repo.vue';
import RepoEditButton from './components/repo_edit_button.vue';
import newBranchForm from './components/new_branch_form.vue';
import Translate from '../vue_shared/translate';

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
  Store.service = Service;
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
  Store.checkIsCommitable();
  Store.setBranchHash();
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

function initNewBranchForm() {
  const el = document.querySelector('.js-new-branch-dropdown');

  if (!el) return null;

  return new Vue({
    el,
    components: {
      newBranchForm,
    },
    render(createElement) {
      return createElement('new-branch-form', {
        props: {
          currentBranch: Store.currentBranch,
        },
      });
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
  initNewBranchForm();
}

$(initRepoBundle);

export default initRepoBundle;
