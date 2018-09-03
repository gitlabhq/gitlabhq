<script>
import Mousetrap from 'mousetrap';
import { mapActions, mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import NewModal from './new_dropdown/modal.vue';
import IdeSidebar from './ide_side_bar.vue';
import RepoTabs from './repo_tabs.vue';
import IdeStatusBar from './ide_status_bar.vue';
import RepoEditor from './repo_editor.vue';
import FindFile from './file_finder/index.vue';
import RightPane from './panes/right.vue';
import ErrorMessage from './error_message.vue';

const originalStopCallback = Mousetrap.stopCallback;

export default {
  components: {
    NewModal,
    IdeSidebar,
    RepoTabs,
    IdeStatusBar,
    RepoEditor,
    FindFile,
    RightPane,
    ErrorMessage,
  },
  computed: {
    ...mapState([
      'openFiles',
      'viewer',
      'currentMergeRequestId',
      'fileFindVisible',
      'emptyStateSvgPath',
      'currentProjectId',
      'errorMessage',
    ]),
    ...mapGetters(['activeFile', 'hasChanges', 'someUncommitedChanges']),
  },
  mounted() {
    window.onbeforeunload = e => this.onBeforeUnload(e);

    Mousetrap.bind(['t', 'command+p', 'ctrl+p'], e => {
      if (e.preventDefault) {
        e.preventDefault();
      }

      this.toggleFileFinder(!this.fileFindVisible);
    });

    Mousetrap.stopCallback = (e, el, combo) => this.mousetrapStopCallback(e, el, combo);
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
    onBeforeUnload(e = {}) {
      const returnValue = __('Are you sure you want to lose unsaved changes?');

      if (!this.someUncommitedChanges) return undefined;

      Object.assign(e, {
        returnValue,
      });
      return returnValue;
    },
    mousetrapStopCallback(e, el, combo) {
      if (
        (combo === 't' && el.classList.contains('dropdown-input-field')) ||
        el.classList.contains('inputarea')
      ) {
        return true;
      } else if (combo === 'command+p' || combo === 'ctrl+p') {
        return false;
      }

      return originalStopCallback(e, el, combo);
    },
  },
};
</script>

<template>
  <article class="ide position-relative d-flex flex-column align-items-stretch">
    <error-message
      v-if="errorMessage"
      :message="errorMessage"
    />
    <div
      class="ide-view flex-grow d-flex"
    >
      <find-file
        v-show="fileFindVisible"
      />
      <ide-sidebar />
      <div
        class="multi-file-edit-pane"
      >
        <template
          v-if="activeFile"
        >
          <repo-tabs
            :active-file="activeFile"
            :files="openFiles"
            :viewer="viewer"
            :has-changes="hasChanges"
            :merge-request-id="currentMergeRequestId"
          />
          <repo-editor
            :file="activeFile"
            class="multi-file-edit-pane-content"
          />
        </template>
        <template
          v-else
        >
          <div
            v-once
            class="ide-empty-state"
          >
            <div class="row js-empty-state">
              <div class="col-12">
                <div class="svg-content svg-250">
                  <img :src="emptyStateSvgPath" />
                </div>
              </div>
              <div class="col-12">
                <div class="text-content text-center">
                  <h4>
                    Welcome to the GitLab IDE
                  </h4>
                  <p>
                    Select a file from the left sidebar to begin editing.
                    Afterwards, you'll be able to commit your changes.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
      <right-pane
        v-if="currentProjectId"
      />
    </div>
    <ide-status-bar :file="activeFile"/>
    <new-modal />
  </article>
</template>
