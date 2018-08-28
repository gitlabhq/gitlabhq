<script>
import _ from 'underscore';
import { n__, s__, sprintf } from '~/locale';
import { mergeUrlParams, webIDEUrl } from '~/lib/utils/url_utility';
import Icon from '~/vue_shared/components/icon.vue';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  name: 'MRWidgetHeader',
  components: {
    Icon,
    clipboardButton,
    TooltipOnTruncate,
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
    commitsBehindText() {
      return sprintf(s__('mrWidget|The source branch is %{commitsBehindLinkStart}%{commitsBehind}%{commitsBehindLinkEnd} the target branch'), {
        commitsBehindLinkStart: `<a href="${_.escape(this.mr.targetBranchPath)}">`,
        commitsBehind: n__('%d commit behind', '%d commits behind', this.mr.divergedCommitsCount),
        commitsBehindLinkEnd: '</a>',
      }, false);
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
    webIdePath() {
      return mergeUrlParams({
        target_project: this.mr.sourceProjectFullPath !== this.mr.targetProjectFullPath ?
          this.mr.targetProjectFullPath : '',
      }, webIDEUrl(`/${this.mr.sourceProjectFullPath}/merge_requests/${this.mr.iid}`));
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
          <tooltip-on-truncate
            :title="mr.sourceBranch"
            truncate-target="child"
            class="label-branch label-truncate js-source-branch"
            v-html="mr.sourceBranchLink"
          /><clipboard-button
            :text="branchNameClipboardData"
            :title="__('Copy branch name to clipboard')"
            css-class="btn-default btn-transparent btn-clipboard"
          />
          {{ s__("mrWidget|into") }}
          <tooltip-on-truncate
            :title="mr.targetBranch"
            truncate-target="child"
            class="label-branch label-truncate"
          >
            <a
              :href="mr.targetBranchTreePath"
              class="js-target-branch"
            >
              {{ mr.targetBranch }}
            </a>
          </tooltip-on-truncate>
        </strong>
        <div
          v-if="shouldShowCommitsBehindText"
          class="diverged-commits-count"
          v-html="commitsBehindText"
        >
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
