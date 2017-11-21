import Vue from 'vue';
import { mapActions } from 'vuex';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import Ide from './components/ide.vue';
import RepoEditButton from './components/repo_edit_button.vue';
import newBranchForm from './components/new_branch_form.vue';
import newDropdown from './components/new_dropdown/index.vue';
import store from './stores';
import router from './ide_router';
import Translate from '../vue_shared/translate';

function initIde(el) {
  if (!el) return null;

  return new Vue({
    el,
    store,
    router,
    components: {
      ide: Ide,
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
          url: data.projectUrl,
        },
        endpoints: {
          rootEndpoint: data.url,
          newMergeRequestUrl: data.newMergeRequestUrl,
          rootUrl: data.rootUrl,
        },
        canCommit: convertPermissionToBoolean(data.canCommit),
        onTopOfBranch: convertPermissionToBoolean(data.onTopOfBranch),
        currentRef: data.ref,
        path: data.currentPath,
        currentBranch: data.currentBranch,
        isRoot: convertPermissionToBoolean(data.root),
        isInitialRoot: convertPermissionToBoolean(data.root),
      });
    },
    render(createElement) {
      return createElement('ide');
    },
  });
}

function initIdeEditButton(el) {
  return new Vue({
    el,
    store,
    components: {
      repoEditButton: RepoEditButton,
    },
    render(createElement) {
      return createElement('repo-edit-button');
    },
  });
}

function initNewDropdown(el) {
  return new Vue({
    el,
    store,
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
    store,
    render(createElement) {
      return createElement('new-branch-form');
    },
  });
}

const ide = document.getElementById('ide');
const editButton = document.querySelector('.editable-mode');
const newDropdownHolder = document.querySelector('.js-new-dropdown');

Vue.use(Translate);

initIde(ide);
initIdeEditButton(editButton);
initNewBranchForm();
initNewDropdown(newDropdownHolder);
