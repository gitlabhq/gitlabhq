<script>
import { mapState, mapGetters } from 'vuex';
import IdeSidebar from './ide_side_bar.vue';
import RepoTabs from './repo_tabs.vue';
import IdeStatusBar from './ide_status_bar.vue';
import RepoEditor from './repo_editor.vue';
import FindFile from './file_finder/index.vue';

const originalStopCallback = Mousetrap.stopCallback;

export default {
  components: {
    IdeSidebar,
    RepoTabs,
    IdeStatusBar,
    RepoEditor,
    FindFile,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'changedFiles',
      'openFiles',
      'viewer',
      'currentMergeRequestId',
      'fileFindVisible',
    ]),
    ...mapGetters(['activeFile', 'hasChanges']),
  },
  mounted() {
    const returnValue = 'Are you sure you want to lose unsaved changes?';
    window.onbeforeunload = e => {
      if (!this.changedFiles.length) return undefined;

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
      mousetrapStopCallback(e, el, combo) {
        if (combo === 't' && el.classList.contains('dropdown-input-field')) {
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
  <div
    class="ide-view"
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
          class="multi-file-edit-pane-content"
          :file="activeFile"
        />
        <ide-status-bar
          :file="activeFile"
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
            <div class="col-xs-12">
              <div class="svg-content svg-250">
                <img :src="emptyStateSvgPath" />
              </div>
            </div>
            <div class="col-xs-12">
              <div class="text-content text-center">
                <h4>
                  Welcome to the GitLab IDE
                </h4>
                <p>
                  You can select a file in the left sidebar to begin
                  editing and use the right sidebar to commit your changes.
                </p>
              </div>
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
