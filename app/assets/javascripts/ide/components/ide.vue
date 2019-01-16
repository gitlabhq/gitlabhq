<script>
import Vue from 'vue';
import { mapActions, mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import FindFile from '~/vue_shared/components/file_finder/index.vue';
import NewModal from './new_dropdown/modal.vue';
import IdeSidebar from './ide_side_bar.vue';
import RepoTabs from './repo_tabs.vue';
import IdeStatusBar from './ide_status_bar.vue';
import RepoEditor from './repo_editor.vue';
import RightPane from './panes/right.vue';
import ErrorMessage from './error_message.vue';
import CommitEditorHeader from './commit_sidebar/editor_header.vue';

export default {
  components: {
    NewModal,
    IdeSidebar,
    RepoTabs,
    IdeStatusBar,
    RepoEditor,
    FindFile,
    ErrorMessage,
    CommitEditorHeader,
  },
  props: {
    rightPaneComponent: {
      type: Vue.Component,
      required: false,
      default: () => RightPane,
    },
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
      'loading',
    ]),
    ...mapGetters([
      'activeFile',
      'hasChanges',
      'someUncommittedChanges',
      'isCommitModeActive',
      'allBlobs',
    ]),
  },
  mounted() {
    window.onbeforeunload = e => this.onBeforeUnload(e);
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
    onBeforeUnload(e = {}) {
      const returnValue = __('Are you sure you want to lose unsaved changes?');

      if (!this.someUncommittedChanges) return undefined;

      Object.assign(e, {
        returnValue,
      });
      return returnValue;
    },
    openFile(file) {
      this.$router.push(`/project${file.url}`);
    },
  },
};
</script>

<template>
  <article class="ide position-relative d-flex flex-column align-items-stretch">
    <error-message v-if="errorMessage" :message="errorMessage" />
    <div class="ide-view flex-grow d-flex">
      <find-file
        v-show="fileFindVisible"
        :files="allBlobs"
        :visible="fileFindVisible"
        :loading="loading"
        @toggle="toggleFileFinder"
        @click="openFile"
      />
      <ide-sidebar />
      <div class="multi-file-edit-pane">
        <template v-if="activeFile">
          <commit-editor-header v-if="isCommitModeActive" :active-file="activeFile" />
          <repo-tabs
            v-else
            :active-file="activeFile"
            :files="openFiles"
            :viewer="viewer"
            :has-changes="hasChanges"
            :merge-request-id="currentMergeRequestId"
          />
          <repo-editor :file="activeFile" class="multi-file-edit-pane-content" />
        </template>
        <template v-else>
          <div v-once class="ide-empty-state">
            <div class="row js-empty-state">
              <div class="col-12">
                <div class="svg-content svg-250"><img :src="emptyStateSvgPath" /></div>
              </div>
              <div class="col-12">
                <div class="text-content text-center">
                  <h4>Welcome to the GitLab IDE</h4>
                  <p>
                    Select a file from the left sidebar to begin editing. Afterwards, you'll be able
                    to commit your changes.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
      <component :is="rightPaneComponent" v-if="currentProjectId" />
    </div>
    <ide-status-bar :file="activeFile" />
    <new-modal />
  </article>
</template>
