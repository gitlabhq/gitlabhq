<script>
import tooltip from '~/vue_shared/directives/tooltip';
import { n__ } from '~/locale';
import icon from '~/vue_shared/components/icon.vue';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'MRWidgetHeader',
  directives: {
    tooltip,
  },
  components: {
    icon,
    clipboardButton,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  computed: {
    shouldShowCommitsBehindText() {
      return this.mr.divergedCommitsCount > 0;
    },
    commitsText() {
      return n__('%d commit behind', '%d commits behind', this.mr.divergedCommitsCount);
    },
    branchNameClipboardData() {
      // This supports code in app/assets/javascripts/copy_to_clipboard.js that
      // works around ClipboardJS limitations to allow the context-specific
      // copy/pasting of plain text or GFM.
      return JSON.stringify({
        text: this.mr.sourceBranch,
        gfm: `\`${this.mr.sourceBranch}\``,
      });
    },
    isSourceBranchLong() {
      return this.isBranchTitleLong(this.mr.sourceBranch);
    },
    isTargetBranchLong() {
      return this.isBranchTitleLong(this.mr.targetBranch);
    },
    webIdePath() {
      return `${gon.relative_url_root}/-/ide/project${this.mr.statusPath.replace('.json', '')}`;
    },
  },
  methods: {
    isBranchTitleLong(branchTitle) {
      return branchTitle.length > 32;
    },
  },
};
</script>
<template>
  <div class="mr-source-target">
    <div class="normal">
      <strong>
        {{ s__("mrWidget|Request to merge") }}
        <span
          class="label-branch js-source-branch"
          :class="{ 'label-truncated': isSourceBranchLong }"
          :title="isSourceBranchLong ? mr.sourceBranch : ''"
          data-placement="bottom"
          :v-tooltip="isSourceBranchLong"
          v-html="mr.sourceBranchLink"
        >
        </span>

        <clipboard-button
          :text="branchNameClipboardData"
          :title="__('Copy branch name to clipboard')"
          css-class="btn-default btn-transparent btn-clipboard"
        />

        {{ s__("mrWidget|into") }}

        <span
          class="label-branch"
          :v-tooltip="isTargetBranchLong"
          :class="{ 'label-truncatedtooltip': isTargetBranchLong }"
          :title="isTargetBranchLong ? mr.targetBranch : ''"
          data-placement="bottom"
        >
          <a
            :href="mr.targetBranchTreePath"
            class="js-target-branch"
          >
            {{ mr.targetBranch }}
          </a>
        </span>
      </strong>
      <span
        v-if="shouldShowCommitsBehindText"
        class="diverged-commits-count"
      >
        (<a :href="mr.targetBranchPath">{{ commitsText }}</a>)
      </span>
    </div>

    <div v-if="mr.isOpen">
      <a
        v-if="!mr.sourceBranchRemoved"
        :href="webIdePath"
        class="btn btn-sm btn-default inline js-web-ide"
      >
        {{ s__("mrWidget|Web IDE") }}
      </a>
      <button
        data-target="#modal_merge_info"
        data-toggle="modal"
        :disabled="mr.sourceBranchRemoved"
        class="btn btn-sm btn-default inline js-check-out-branch"
        type="button"
      >
        {{ s__("mrWidget|Check out branch") }}
      </button>
      <span class="dropdown prepend-left-10">
        <button
          type="button"
          class="btn btn-sm inline dropdown-toggle"
          data-toggle="dropdown"
          aria-label="Download as"
          aria-haspopup="true"
          aria-expanded="false"
        >
          <icon name="download" />
          <i
            class="fa fa-caret-down"
            aria-hidden="true">
          </i>
        </button>
        <ul class="dropdown-menu dropdown-menu-align-right">
          <li>
            <a
              class="js-download-email-patches"
              :href="mr.emailPatchesPath"
              download
            >
              {{ s__("mrWidget|Email patches") }}
            </a>
          </li>
          <li>
            <a
              class="js-download-plain-diff"
              :href="mr.plainDiffPath"
              download
            >
              {{ s__("mrWidget|Plain diff") }}
            </a>
          </li>
        </ul>
      </span>
    </div>
  </div>
</template>
