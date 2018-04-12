<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import Mousetrap from 'mousetrap';
import ideSidebar from './ide_side_bar.vue';
import ideContextbar from './ide_context_bar.vue';
import repoTabs from './repo_tabs.vue';
import ideStatusBar from './ide_status_bar.vue';
import repoEditor from './repo_editor.vue';
import FindFile from './file_finder/index.vue';

export default {
  components: {
    ideSidebar,
    ideContextbar,
    repoTabs,
    ideStatusBar,
    repoEditor,
    FindFile,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    noChangesStateSvgPath: {
      type: String,
      required: true,
    },
    committedStateSvgPath: {
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

      Object.assign(e, {
        returnValue,
      });
      return returnValue;
    };

    Mousetrap.bind('t', e => {
      e.preventDefault();
      this.toggleFileFinder(true);
    });
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
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
    <ide-contextbar
      :no-changes-state-svg-path="noChangesStateSvgPath"
      :committed-state-svg-path="committedStateSvgPath"
    />
  </div>
</template>
