<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLoadingIcon, GlBroadcastMessage, GlLink, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import {
  WEBIDE_MARK_APP_START,
  WEBIDE_MARK_FILE_FINISH,
  WEBIDE_MARK_FILE_CLICKED,
  WEBIDE_MEASURE_FILE_AFTER_INTERACTION,
  WEBIDE_MEASURE_BEFORE_VUE,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import { modalTypes } from '../constants';
import eventHub from '../eventhub';
import { measurePerformance } from '../utils';
import CannotPushCodeAlert from './cannot_push_code_alert.vue';
import IdeSidebar from './ide_side_bar.vue';
import RepoEditor from './repo_editor.vue';

eventHub.$on(WEBIDE_MEASURE_FILE_AFTER_INTERACTION, () =>
  measurePerformance(
    WEBIDE_MARK_FILE_FINISH,
    WEBIDE_MEASURE_FILE_AFTER_INTERACTION,
    WEBIDE_MARK_FILE_CLICKED,
  ),
);

const removalAnnouncementHelpPagePath = helpPagePath(
  'update/deprecations.md#legacy-web-ide-is-deprecated',
);

export default {
  components: {
    IdeSidebar,
    RepoEditor,
    GlButton,
    GlLoadingIcon,
    ErrorMessage: () => import(/* webpackChunkName: 'ide_runtime' */ './error_message.vue'),
    CommitEditorHeader: () =>
      import(/* webpackChunkName: 'ide_runtime' */ './commit_sidebar/editor_header.vue'),
    RepoTabs: () => import(/* webpackChunkName: 'ide_runtime' */ './repo_tabs.vue'),
    IdeStatusBar: () => import(/* webpackChunkName: 'ide_runtime' */ './ide_status_bar.vue'),
    FindFile: () =>
      import(/* webpackChunkName: 'ide_runtime' */ '~/vue_shared/components/file_finder/index.vue'),
    RightPane: () => import(/* webpackChunkName: 'ide_runtime' */ './panes/right.vue'),
    NewModal: () => import(/* webpackChunkName: 'ide_runtime' */ './new_dropdown/modal.vue'),
    CannotPushCodeAlert,
    GlBroadcastMessage,
    GlLink,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      loadDeferred: false,
      skipBeforeUnload: false,
    };
  },
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
      'canPushCodeStatus',
      'activeFile',
      'someUncommittedChanges',
      'isCommitModeActive',
      'allBlobs',
      'emptyRepo',
      'currentTree',
      'hasCurrentProject',
      'editorTheme',
      'getUrlForPath',
    ]),
    themeName() {
      return window.gon?.user_color_scheme;
    },
  },
  mounted() {
    window.onbeforeunload = (e) => this.onBeforeUnload(e);

    eventHub.$on('skip-beforeunload', this.handleSkipBeforeUnload);

    if (this.themeName)
      document.querySelector('.navbar-gitlab')?.classList.add(`theme-${this.themeName}`);
  },
  destroyed() {
    eventHub.$off('skip-beforeunload', this.handleSkipBeforeUnload);
  },
  beforeCreate() {
    performanceMarkAndMeasure({
      mark: WEBIDE_MARK_APP_START,
      measures: [
        {
          name: WEBIDE_MEASURE_BEFORE_VUE,
        },
      ],
    });
  },
  methods: {
    ...mapActions(['toggleFileFinder']),
    onBeforeUnload(e = {}) {
      if (this.skipBeforeUnload) {
        this.skipBeforeUnload = false;
        return undefined;
      }

      const returnValue = __('Are you sure you want to lose unsaved changes?');

      if (!this.someUncommittedChanges) return undefined;

      Object.assign(e, {
        returnValue,
      });
      return returnValue;
    },
    handleSkipBeforeUnload() {
      this.skipBeforeUnload = true;
    },
    openFile(file) {
      this.$router.push(this.getUrlForPath(file.path));
    },
    createNewFile() {
      this.$refs.newModal.open(modalTypes.blob);
    },
    loadDeferredComponents() {
      this.loadDeferred = true;
    },
  },
  removalAnnouncementHelpPagePath,
};
</script>

<template>
  <article
    class="ide position-relative flex-column align-items-stretch gl-flex"
    :class="{ [`theme-${themeName}`]: themeName }"
  >
    <gl-broadcast-message icon-name="warning" theme="red" :dismissible="false">
      {{ __('The legacy Vue-based GitLab Web IDE will be removed in GitLab 18.0.') }}
      <gl-sprintf
        :message="
          __('To prepare for this removal, see %{linkStart}deprecations and removals%{linkEnd}.')
        "
      >
        <template #link="{ content }">
          <gl-link class="!gl-text-inherit" :href="$options.removalAnnouncementHelpPagePath">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-broadcast-message>
    <cannot-push-code-alert
      v-if="!canPushCodeStatus.isAllowed"
      :message="canPushCodeStatus.message"
      :action="canPushCodeStatus.action"
    />
    <error-message v-if="errorMessage" :message="errorMessage" />
    <div class="ide-view gl-flex gl-grow">
      <template v-if="loadDeferred">
        <find-file
          :files="allBlobs"
          :visible="fileFindVisible"
          :loading="loading"
          @toggle="toggleFileFinder"
          @click="openFile"
        />
      </template>
      <ide-sidebar @tree-ready="loadDeferredComponents" />
      <div class="multi-file-edit-pane">
        <template v-if="activeFile">
          <template v-if="loadDeferred">
            <commit-editor-header v-if="isCommitModeActive" :active-file="activeFile" />
            <repo-tabs v-else :active-file="activeFile" :files="openFiles" :viewer="viewer" />
          </template>
          <repo-editor :file="activeFile" class="multi-file-edit-pane-content" />
        </template>
        <template v-else>
          <div class="ide-empty-state">
            <div class="row js-empty-state">
              <div class="col-12">
                <div class="svg-content svg-150"><img :src="emptyStateSvgPath" /></div>
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
                    <gl-button
                      variant="confirm"
                      category="primary"
                      :title="__('New file')"
                      :aria-label="__('New file')"
                      @click="createNewFile()"
                    >
                      {{ __('New file') }}
                    </gl-button>
                  </template>
                  <gl-loading-icon v-else-if="!currentTree || currentTree.loading" size="lg" />
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
      <template v-if="loadDeferred">
        <right-pane v-if="currentProjectId" />
      </template>
    </div>
    <template v-if="loadDeferred">
      <ide-status-bar />
      <new-modal ref="newModal" />
    </template>
  </article>
</template>
