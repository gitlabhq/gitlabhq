<script>
import tooltip from '~/vue_shared/directives/tooltip';
import { n__ } from '~/locale';
import { mergeUrlParams, webIDEUrl } from '~/lib/utils/url_utility';
import Icon from '~/vue_shared/components/icon.vue';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'MRWidgetHeader',
  directives: {
    tooltip,
  },
  components: {
    Icon,
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
      return mergeUrlParams({
        target_project: this.mr.sourceProjectFullPath !== this.mr.targetProjectFullPath ?
          this.mr.targetProjectFullPath : '',
      }, webIDEUrl(`/${this.mr.sourceProjectFullPath}/merge_requests/${this.mr.iid}`));
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
  <div class="mr-source-target append-bottom-default">
    <div class="git-merge-icon-container append-right-default">
      <icon name="git-merge" />
    </div>
    <div class="git-merge-container d-flex">
      <div class="normal">
        <strong>
          {{ s__("mrWidget|Request to merge") }}
          <span
            :class="{ 'label-truncated': isSourceBranchLong }"
            :title="isSourceBranchLong ? mr.sourceBranch : ''"
            :v-tooltip="isSourceBranchLong"
            class="label-branch js-source-branch"
            data-placement="bottom"
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
            :v-tooltip="isTargetBranchLong"
            :class="{ 'label-truncatedtooltip': isTargetBranchLong }"
            :title="isTargetBranchLong ? mr.targetBranch : ''"
            class="label-branch"
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
        <div
          v-if="shouldShowCommitsBehindText"
          class="diverged-commits-count"
        >
          <span class="monospace">{{ mr.sourceBranch }}</span>
          is {{ commitsText }}
          <span class="monospace">{{ mr.targetBranch }}</span>
        </div>
      </div>

      <div
        v-if="mr.isOpen"
        class="branch-actions"
      >
        <a
          v-if="!mr.sourceBranchRemoved"
          :href="webIdePath"
          class="btn btn-default inline js-web-ide d-none d-md-inline-block"
        >
          {{ s__("mrWidget|Open in Web IDE") }}
        </a>
        <button
          :disabled="mr.sourceBranchRemoved"
          data-target="#modal_merge_info"
          data-toggle="modal"
          class="btn btn-default inline js-check-out-branch"
          type="button"
        >
          {{ s__("mrWidget|Check out branch") }}
        </button>
        <span class="dropdown prepend-left-10">
          <button
            type="button"
            class="btn inline dropdown-toggle"
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
          <ul class="dropdown-menu dropdown-menu-right">
            <li>
              <a
                :href="mr.emailPatchesPath"
                class="js-download-email-patches"
                download
              >
                {{ s__("mrWidget|Email patches") }}
              </a>
            </li>
            <li>
              <a
                :href="mr.plainDiffPath"
                class="js-download-plain-diff"
                download
              >
                {{ s__("mrWidget|Plain diff") }}
              </a>
            </li>
          </ul>
        </span>
      </div>
    </div>
  </div>
</template>
