<script>
import { mapActions } from 'vuex';
import _ from 'underscore';
import { __, sprintf } from '~/locale';
import createFlash from '~/flash';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DiffFileHeader from './diff_file_header.vue';
import DiffContent from './diff_content.vue';

export default {
  components: {
    DiffFileHeader,
    DiffContent,
    LoadingIcon,
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
  },
  data() {
    return {
      isLoadingCollapsedDiff: false,
      forkMessageVisible: false,
    };
  },
  computed: {
    isCollapsed() {
      return this.file.collapsed || false;
    },
    viewBlobLink() {
      return sprintf(
        __('You can %{linkStart}view the blob%{linkEnd} instead.'),
        {
          linkStart: `<a href="${_.escape(this.file.viewPath)}">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    showExpandMessage() {
      return this.isCollapsed && !this.isLoadingCollapsedDiff && !this.file.tooLarge;
    },
    showLoadingIcon() {
      return this.isLoadingCollapsedDiff || (!this.file.renderIt && !this.isCollapsed);
    },
  },
  methods: {
    ...mapActions('diffs', ['loadCollapsedDiff']),
    handleToggle() {
      const { collapsed, highlightedDiffLines, parallelDiffLines } = this.file;

      if (
        collapsed &&
        !highlightedDiffLines &&
        parallelDiffLines !== undefined &&
        !parallelDiffLines.length
      ) {
        this.handleLoadCollapsedDiff();
      } else {
        this.file.collapsed = !this.file.collapsed;
        this.file.renderIt = true;
      }
    },
    handleLoadCollapsedDiff() {
      this.isLoadingCollapsedDiff = true;

      this.loadCollapsedDiff(this.file)
        .then(() => {
          this.isLoadingCollapsedDiff = false;
          this.file.collapsed = false;
          this.file.renderIt = true;
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
    :id="file.fileHash"
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

    <div
      v-if="forkMessageVisible"
      class="js-file-fork-suggestion-section file-fork-suggestion">
      <span class="file-fork-suggestion-note">
        You're not allowed to <span class="js-file-fork-suggestion-section-action">edit</span>
        files in this project directly. Please fork this project,
        make your changes there, and submit a merge request.
      </span>
      <a
        :href="file.forkPath"
        class="js-fork-suggestion-button btn btn-grouped btn-inverted btn-success"
      >
        Fork
      </a>
      <button
        class="js-cancel-fork-suggestion-button btn btn-grouped"
        type="button"
        @click="hideForkMessage"
      >
        Cancel
      </button>
    </div>

    <diff-content
      v-if="!isCollapsed && file.renderIt"
      :class="{ hidden: isCollapsed || file.tooLarge }"
      :diff-file="file"
    />
    <loading-icon
      v-else-if="showLoadingIcon"
      class="diff-content loading"
    />
    <div
      v-if="showExpandMessage"
      class="nothing-here-block diff-collapsed"
    >
      {{ __('This diff is collapsed.') }}
      <a
        class="click-to-expand js-click-to-expand"
        href="#"
        @click.prevent="handleToggle"
      >
        {{ __('Click to expand it.') }}
      </a>
    </div>
    <div
      v-if="file.tooLarge"
      class="nothing-here-block diff-collapsed js-too-large-diff"
    >
      {{ __('This source diff could not be displayed because it is too large.') }}
      <span v-html="viewBlobLink"></span>
    </div>
  </div>
</template>
