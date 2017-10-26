import Vue from 'vue';
import { mapActions } from 'vuex';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import Service from './services/repo_service';
import Store from './stores/repo_store';
import Repo from './components/repo.vue';
import RepoEditButton from './components/repo_edit_button.vue';
import newBranchForm from './components/new_branch_form.vue';
import newDropdown from './components/new_dropdown/index.vue';
import vStore from './stores';
import Translate from '../vue_shared/translate';

function setInitialStore(data) {
  Store.service = Service;
  Store.service.refsUrl = data.refsUrl;
  Store.path = data.currentPath;
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
    store: vStore,
    components: {
      repo: Repo,
    },
    methods: {
      ...mapActions([
        'setInitialData',
      ]),
    },
    created() {
      const data = el.dataset;

      this.setInitialData({
        project: {
          id: data.projectId,
          name: data.projectName,
        },
        endpoints: {
          rootEndpoint: data.url,
          newMergeRequestUrl: data.newMergeRequestUrl,
          rootUrl: data.rootUrl,
        },
        canCommit: convertPermissionToBoolean(data.canCommit),
        onTopOfBranch: convertPermissionToBoolean(data.onTopOfBranch),
        currentRef: data.ref,
        // TODO: get through data attribute
        currentBranch: document.querySelector('.js-project-refs-dropdown').dataset.ref,
        isRoot: convertPermissionToBoolean(data.root),
        isInitialRoot: convertPermissionToBoolean(data.root),
      });
    },
    render(createElement) {
      return createElement('repo');
    },
  });
}

function initRepoEditButton(el) {
  return new Vue({
    el,
    store: vStore,
    components: {
      repoEditButton: RepoEditButton,
    },
  });
}

function initNewDropdown(el) {
  return new Vue({
    el,
    components: {
      newDropdown,
    },
    render(createElement) {
      return createElement('new-dropdown');
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
    store: vStore,
    render(createElement) {
      return createElement('new-branch-form');
    },
  });
}

const repo = document.getElementById('repo');
const editButton = document.querySelector('.editable-mode');
const newDropdownHolder = document.querySelector('.js-new-dropdown');
setInitialStore(repo.dataset);

Vue.use(Translate);

initRepo(repo);
initRepoEditButton(editButton);
initNewBranchForm();
initNewDropdown(newDropdownHolder);
