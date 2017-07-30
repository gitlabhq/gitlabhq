/* global monaco */
import $ from 'jquery';
import Vue from 'vue';
import RepoSidebar from './repo_sidebar.vue';
import EditButton from './repo_edit_button';
import Service from './repo_service';
import Store from './repo_store';
import RepoCommitSection from './repo_commit_section.vue';
import RepoTabs from './repo_tabs.vue';
import RepoFileButtons from './repo_file_buttons.vue';
import RepoBinaryViewer from './repo_binary_viewer.vue';
import RepoEditor from './repo_editor.vue';
import monacoLoader from './monaco_loader';
import RepoMixin from './repo_mixin';
import PopupDialog from '../vue_shared/components/popup_dialog.vue'

function repoEditorLoader() {
  return new Promise((resolve) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      Store.monaco = monaco;

      resolve(RepoEditor);
    });
  });
}

function initDropdowns() {
  $('.project-refs-target-form').hide();
  $('.fa-long-arrow-right').hide();
}

function addEventsForNonVueEls() {
  $(document).on('change', '.dropdown', () => {
    Store.targetBranch = $('.project-refs-target-form input[name="ref"]').val();
  });

  window.onbeforeunload = function (e) {
    const hasChanged = Store.openedFiles
      .some(file => file.changed);
    if(!hasChanged) return;
    e = e || window.event;
    if (e) {
      e.returnValue = 'Are you sure you want to lose unsaved changes?';
    }
    // For Safari
    return 'Are you sure you want to lose unsaved changes?';
  };
}

function initRepo() {
  const repo = document.getElementById('repo');


  Store.service = Service;
  Store.service.url = repo.dataset.url;
  Store.service.refsUrl = repo.dataset.refsUrl;
  Store.projectId = repo.dataset.projectId;
  Store.projectName = repo.dataset.projectName;
  Store.projectUrl = repo.dataset.projectUrl;
  Store.currentBranch = $('button.dropdown-menu-toggle').attr('data-ref');
  Store.checkIsCommitable();
  addEventsForNonVueEls();
  initDropdowns();

  this.vm = new Vue({
    el: repo,
    data: () => Store,
    template: `
      <div class="tree-content-holder">
        <repo-sidebar/><div class="panel-right" :class="{'edit-mode': editMode}">
          <repo-tabs/>
          <repo-file-buttons/>
          <repo-editor/>
          <repo-binary-viewer/>
        </div>
        <repo-commit-section/>
        <popup-dialog primary-button-label="Discard changes" :open="dialog.open" kind="warning" title="Are you sure?" body="Are you sure you want to discard your changes?" @toggle="dialogToggled" @submit="dialogSubmitted"></popup-dialog>
      </div>
    `,
    mixins: [RepoMixin],
    components: {
      'repo-sidebar': RepoSidebar,
      'repo-tabs': RepoTabs,
      'repo-file-buttons': RepoFileButtons,
      'repo-binary-viewer': RepoBinaryViewer,
      'repo-editor': repoEditorLoader,
      'repo-commit-section': RepoCommitSection,
      'popup-dialog': PopupDialog,
    },

    methods: {
      dialogToggled(toggle) {
        this.dialog.open = toggle;
      },

      dialogSubmitted(status) {
        this.dialog.open = false;
        this.dialog.status = status;
      }
    }
  });

  const editButton = document.getElementById('editable-mode');
  Store.editButton = new EditButton(editButton);
}

$(initRepo);

export default initRepo;
