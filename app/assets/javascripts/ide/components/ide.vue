<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { modalTypes } from '../constants';
import FindFile from '~/vue_shared/components/file_finder/index.vue';
import NewModal from './new_dropdown/modal.vue';
import IdeSidebar from './ide_side_bar.vue';
import RepoTabs from './repo_tabs.vue';
import IdeStatusBar from './ide_status_bar.vue';
import RepoEditor from './repo_editor.vue';
import RightPane from './panes/right.vue';
import ErrorMessage from './error_message.vue';
import CommitEditorHeader from './commit_sidebar/editor_header.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

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
    GlDeprecatedButton,
    GlLoadingIcon,
    RightPane,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState([
      'openFiles',
      'viewer',
      'fileFindVisible',
      'emptyStateSvgPath',
      'currentProjectId',
      'errorMessage',
      'loading',
    ]),
    ...mapGetters([
      'activeFile',
      'someUncommittedChanges',
      'isCommitModeActive',
      'allBlobs',
      'emptyRepo',
      'currentTree',
      'editorTheme',
    ]),
    themeName() {
      return window.gon?.user_color_scheme;
    },
  },
  mounted() {
    window.onbeforeunload = e => this.onBeforeUnload(e);

    if (this.themeName)
      document.querySelector('.navbar-gitlab').classList.add(`theme-${this.themeName}`);
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
    createNewFile() {
      this.$refs.newModal.open(modalTypes.blob);
    },
  },
};
</script>

<template>
  <article
    class="ide position-relative d-flex flex-column align-items-stretch"
    :class="{ [`theme-${themeName}`]: themeName }"
  >
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
          <repo-tabs v-else :active-file="activeFile" :files="openFiles" :viewer="viewer" />
          <repo-editor :file="activeFile" class="multi-file-edit-pane-content" />
        </template>
        <template v-else>
          <div class="ide-empty-state">
            <div class="row js-empty-state">
              <div class="col-12">
                <div class="svg-content svg-250"><img :src="emptyStateSvgPath" /></div>
              </div>
              <div class="col-12">
                <div class="text-content text-center">
                  <h4>
                    {{ __('Make and review changes in the browser with the Web IDE') }}
                  </h4>
                  <template v-if="emptyRepo">
                    <p>
                      {{
                        __(
                          "Create a new file as there are no files yet. Afterwards, you'll be able to commit your changes.",
                        )
                      }}
                    </p>
                    <gl-deprecated-button
                      variant="success"
                      :title="__('New file')"
                      :aria-label="__('New file')"
                      data-qa-selector="first_file_button"
                      @click="createNewFile()"
                    >
                      {{ __('New file') }}
                    </gl-deprecated-button>
                  </template>
                  <gl-loading-icon v-else-if="!currentTree || currentTree.loading" size="md" />
                  <p v-else>
                    {{
                      __(
                        "Select a file from the left sidebar to begin editing. Afterwards, you'll be able to commit your changes.",
                      )
                    }}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
      <right-pane v-if="currentProjectId" />
    </div>
    <ide-status-bar />
    <new-modal ref="newModal" />
  </article>
</template>
