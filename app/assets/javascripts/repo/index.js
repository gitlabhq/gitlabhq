import $ from 'jquery';
import Vue from 'vue';
import Translate from '../vue_shared/translate';
import EditButton from './repo_edit_button';
import Service from './services/repo_service';
import Store from './stores/repo_store';
import { initRepoViewModel } from './view_models/repo_view_model';

Vue.use(Translate);

function initDropdowns() {
  $('.project-refs-target-form').hide();
  $('.fa-long-arrow-right').hide();
}

function addEventsForNonVueEls() {
  $(document).on('change', '.dropdown', () => {
    Store.targetBranch = $('.project-refs-target-form input[name="ref"]').val();
  });

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
  Store.currentBranch = $('button.dropdown-menu-toggle').attr('data-ref');
  Store.checkIsCommitable();
}

function initRepo() {
  const repo = document.getElementById('repo');

  setInitialStore(repo.dataset);
  addEventsForNonVueEls();
  initDropdowns();

  initRepoViewModel(repo);

  const editButton = document.getElementById('editable-mode');
  Store.editButton = new EditButton(editButton);
}

$(initRepo);

export default initRepo;
