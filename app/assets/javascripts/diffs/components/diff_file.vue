<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import createFlash from '~/flash';
import eventHub from '../../notes/event_hub';
import DiffFileHeader from './diff_file_header.vue';
import DiffContent from './diff_content.vue';
import { diffViewerErrors } from '~/ide/constants';

export default {
  components: {
    DiffFileHeader,
    DiffContent,
    GlLoadingIcon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    canCurrentUserFork: {
      type: Boolean,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isLoadingCollapsedDiff: false,
      forkMessageVisible: false,
      isCollapsed: this.file.viewer.collapsed || false,
    };
  },
  computed: {
    ...mapState('diffs', ['currentDiffFileId']),
    ...mapGetters(['isNotesFetched']),
    ...mapGetters('diffs', ['getDiffFileDiscussions']),
    viewBlobLink() {
      return sprintf(
        __('You can %{linkStart}view the blob%{linkEnd} instead.'),
        {
          linkStart: `<a href="${_.escape(this.file.view_path)}">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    showLoadingIcon() {
      return this.isLoadingCollapsedDiff || (!this.file.renderIt && !this.isCollapsed);
    },
    hasDiff() {
      return (
        (this.file.highlighted_diff_lines &&
          this.file.parallel_diff_lines &&
          this.file.parallel_diff_lines.length > 0) ||
        !this.file.blob.readable_text
      );
    },
    isFileTooLarge() {
      return this.file.viewer.error === diffViewerErrors.too_large;
    },
    errorMessage() {
      return this.file.viewer.error_message;
    },
    forkMessage() {
      return sprintf(
        __(
          "You're not allowed to %{tag_start}edit%{tag_end} files in this project directly. Please fork this project, make your changes there, and submit a merge request.",
        ),
        {
          tag_start: '<span class="js-file-fork-suggestion-section-action">',
          tag_end: '</span>',
        },
        false,
      );
    },
  },
  watch: {
    isCollapsed: function fileCollapsedWatch(newVal, oldVal) {
      if (!newVal && oldVal && !this.hasDiff) {
        this.handleLoadCollapsedDiff();
      }

      this.setFileCollapsed({ filePath: this.file.file_path, collapsed: newVal });
    },
    'file.viewer.collapsed': function setIsCollapsed(newVal) {
      this.isCollapsed = newVal;
    },
  },
  created() {
    eventHub.$on(`loadCollapsedDiff/${this.file.file_hash}`, this.handleLoadCollapsedDiff);
  },
  methods: {
    ...mapActions('diffs', [
      'loadCollapsedDiff',
      'assignDiscussionsToDiff',
      'setRenderIt',
      'setFileCollapsed',
    ]),
    handleToggle() {
      if (!this.hasDiff) {
        this.handleLoadCollapsedDiff();
      } else {
        this.isCollapsed = !this.isCollapsed;
        this.setRenderIt(this.file);
      }
    },
    handleLoadCollapsedDiff() {
      this.isLoadingCollapsedDiff = true;

      this.loadCollapsedDiff(this.file)
        .then(() => {
          this.isLoadingCollapsedDiff = false;
          this.isCollapsed = false;
          this.setRenderIt(this.file);
        })
        .then(() => {
          requestIdleCallback(
            () => {
              this.assignDiscussionsToDiff(this.getDiffFileDiscussions(this.file));
            },
            { timeout: 1000 },
          );
        })
        .catch(() => {
          this.isLoadingCollapsedDiff = false;
          createFlash(__('Something went wrong on our end. Please try again!'));
        });
    },
    showForkMessage() {
      this.forkMessageVisible = true;
    },
    hideForkMessage() {
      this.forkMessageVisible = false;
    },
  },
};
</script>

<template>
  <div
    :id="file.file_hash"
    :class="{
      'is-active': currentDiffFileId === file.file_hash,
    }"
    class="diff-file file-holder"
  >
    <diff-file-header
      :can-current-user-fork="canCurrentUserFork"
      :diff-file="file"
      :collapsible="true"
      :expanded="!isCollapsed"
      :add-merge-request-buttons="true"
      class="js-file-title file-title"
      @toggleFile="handleToggle"
      @showForkMessage="showForkMessage"
    />

    <div v-if="forkMessageVisible" class="js-file-fork-suggestion-section file-fork-suggestion">
      <span class="file-fork-suggestion-note" v-html="forkMessage"></span>
      <a
        :href="file.fork_path"
        class="js-fork-suggestion-button btn btn-grouped btn-inverted btn-success"
        >{{ __('Fork') }}</a
      >
      <button
        class="js-cancel-fork-suggestion-button btn btn-grouped"
        type="button"
        @click="hideForkMessage"
      >
        {{ __('Cancel') }}
      </button>
    </div>
    <gl-loading-icon v-if="showLoadingIcon" class="diff-content loading" />
    <template v-else>
      <div :id="`diff-content-${file.file_hash}`">
        <div v-if="errorMessage" class="diff-viewer">
          <div class="nothing-here-block" v-html="errorMessage"></div>
        </div>
        <div v-else-if="isCollapsed" class="nothing-here-block diff-collapsed">
          {{ __('This diff is collapsed.') }}
          <a class="click-to-expand js-click-to-expand" href="#" @click.prevent="handleToggle">{{
            __('Click to expand it.')
          }}</a>
        </div>
        <diff-content
          v-else
          :class="{ hidden: isCollapsed || isFileTooLarge }"
          :diff-file="file"
          :help-page-path="helpPagePath"
        />
      </div>
    </template>
  </div>
</template>

<style>
@keyframes shadow-fade {
  from {
    box-shadow: 0 0 4px #919191;
  }

  to {
    box-shadow: 0 0 0 #dfdfdf;
  }
}

.diff-file.is-active {
  box-shadow: 0 0 0 #dfdfdf;
  animation: shadow-fade 1.2s 0.1s 1;
}
</style>
