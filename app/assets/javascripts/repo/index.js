import $ from 'jquery';
import Vue from 'vue';
import Service from './services/repo_service';
import Store from './stores/repo_store';
import Repo from './components/repo.vue';
import RepoEditButton from './components/repo_edit_button.vue';
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

function setInitialStore(dataset) {
  Store.service = Service;
  Store.service.url = dataset.url;
  Store.service.refsUrl = dataset.refsUrl;
  Store.projectId = dataset.projectId;
  Store.projectName = dataset.projectName;
  Store.projectUrl = dataset.projectUrl;
  Store.canCommit = dataset.canCommit;
  Store.onTopOfBranch = dataset.onTopOfBranch;
  Store.customBranchURL = decodeURIComponent(dataset.blobUrl);
  Store.currentBranch = $('button.dropdown-menu-toggle').attr('data-ref');

  Store.checkIsCommitable();
  Service.branchSingle()
    .then(Store.setBranchHash);
    .catch(() => {
      Flash('There was a problem initializing the repo editor.');
    });
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
