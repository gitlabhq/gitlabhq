<script>
import { escape } from 'lodash';
import { n__, s__, sprintf } from '~/locale';
import { mergeUrlParams, webIDEUrl } from '~/lib/utils/url_utility';
import Icon from '~/vue_shared/components/icon.vue';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import MrWidgetIcon from './mr_widget_icon.vue';

export default {
  name: 'MRWidgetHeader',
  components: {
    Icon,
    clipboardButton,
    TooltipOnTruncate,
    MrWidgetIcon,
  },
  directives: {
    tooltip,
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
      return sprintf(
        s__(
          'mrWidget|The source branch is %{commitsBehindLinkStart}%{commitsBehind}%{commitsBehindLinkEnd} the target branch',
        ),
        {
          commitsBehindLinkStart: `<a href="${escape(this.mr.targetBranchPath)}">`,
          commitsBehind: n__('%d commit behind', '%d commits behind', this.mr.divergedCommitsCount),
          commitsBehindLinkEnd: '</a>',
        },
        false,
      );
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
      if (this.mr.canPushToSourceBranch) {
        return mergeUrlParams(
          {
            target_project:
              this.mr.sourceProjectFullPath !== this.mr.targetProjectFullPath
                ? this.mr.targetProjectFullPath
                : '',
          },
          webIDEUrl(`/${this.mr.sourceProjectFullPath}/merge_requests/${this.mr.iid}`),
        );
      }

      return null;
    },
    ideButtonTitle() {
      return !this.mr.canPushToSourceBranch
        ? s__(
            'mrWidget|You are not allowed to edit this project directly. Please fork to make changes.',
          )
        : '';
    },
  },
};
</script>
<template>
  <div class="d-flex mr-source-target append-bottom-default">
    <mr-widget-icon name="git-merge" />
    <div class="git-merge-container d-flex">
      <div class="normal">
        <strong>
          {{ s__('mrWidget|Request to merge') }}
          <tooltip-on-truncate
            :title="mr.sourceBranch"
            truncate-target="child"
            class="label-branch label-truncate js-source-branch"
            v-html="mr.sourceBranchLink"
          /><clipboard-button
            :text="branchNameClipboardData"
            :title="__('Copy branch name')"
            css-class="btn-default btn-transparent btn-clipboard"
          />
          {{ s__('mrWidget|into') }}
          <tooltip-on-truncate
            :title="mr.targetBranch"
            truncate-target="child"
            class="label-branch label-truncate"
          >
            <a :href="mr.targetBranchTreePath" class="js-target-branch"> {{ mr.targetBranch }} </a>
          </tooltip-on-truncate>
        </strong>
        <div
          v-if="shouldShowCommitsBehindText"
          class="diverged-commits-count"
          v-html="commitsBehindText"
        ></div>
      </div>

      <div class="branch-actions d-flex">
        <template v-if="mr.isOpen">
          <a
            v-if="!mr.sourceBranchRemoved"
            v-tooltip
            :href="webIdePath"
            :title="ideButtonTitle"
            :class="{ disabled: !mr.canPushToSourceBranch }"
            class="btn btn-default js-web-ide d-none d-md-inline-block append-right-8"
            data-placement="bottom"
            tabindex="0"
            role="button"
            data-qa-selector="open_in_web_ide_button"
          >
            {{ s__('mrWidget|Open in Web IDE') }}
          </a>
          <button
            :disabled="mr.sourceBranchRemoved"
            data-target="#modal_merge_info"
            data-toggle="modal"
            class="btn btn-default js-check-out-branch append-right-8"
            type="button"
          >
            {{ s__('mrWidget|Check out branch') }}
          </button>
        </template>
        <span class="dropdown">
          <button
            type="button"
            class="btn dropdown-toggle qa-dropdown-toggle"
            data-toggle="dropdown"
            :aria-label="__('Download as')"
            aria-haspopup="true"
            aria-expanded="false"
          >
            <icon name="download" /> <i class="fa fa-caret-down" aria-hidden="true"> </i>
          </button>
          <ul class="dropdown-menu dropdown-menu-right">
            <li>
              <a
                :href="mr.emailPatchesPath"
                class="js-download-email-patches qa-download-email-patches"
                download
              >
                {{ s__('mrWidget|Email patches') }}
              </a>
            </li>
            <li>
              <a
                :href="mr.plainDiffPath"
                class="js-download-plain-diff qa-download-plain-diff"
                download
              >
                {{ s__('mrWidget|Plain diff') }}
              </a>
            </li>
          </ul>
        </span>
      </div>
    </div>
  </div>
</template>
