<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlLink,
  GlTooltipDirective,
  GlModalDirective,
  GlSafeHtmlDirective as SafeHtml,
  GlSprintf,
} from '@gitlab/ui';
import { mergeUrlParams, webIDEUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import MrWidgetHowToMergeModal from './mr_widget_how_to_merge_modal.vue';
import MrWidgetIcon from './mr_widget_icon.vue';

export default {
  name: 'MRWidgetHeader',
  components: {
    clipboardButton,
    TooltipOnTruncate,
    MrWidgetIcon,
    MrWidgetHowToMergeModal,
    GlButton,
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
    SafeHtml,
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
    isFork() {
      return this.mr.sourceProjectFullPath !== this.mr.targetProjectFullPath;
    },
  },
};
</script>
<template>
  <div class="d-flex mr-source-target gl-mb-3">
    <mr-widget-icon name="git-merge" />
    <div class="git-merge-container d-flex">
      <div class="normal">
        <strong>
          {{ s__('mrWidget|Request to merge') }}
          <tooltip-on-truncate
            v-safe-html="mr.sourceBranchLink"
            :title="mr.sourceBranch"
            truncate-target="child"
            class="label-branch label-truncate js-source-branch"
          /><clipboard-button
            data-testid="mr-widget-copy-clipboard"
            :text="branchNameClipboardData"
            :title="__('Copy branch name')"
            category="tertiary"
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
        <div v-if="shouldShowCommitsBehindText" class="diverged-commits-count">
          <gl-sprintf :message="s__('mrWidget|The source branch is %{link} the target branch')">
            <template #link>
              <gl-link :href="mr.targetBranchPath">{{
                n__('%d commit behind', '%d commits behind', mr.divergedCommitsCount)
              }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </div>

      <div class="branch-actions d-flex">
        <template v-if="mr.isOpen">
          <span
            v-if="!mr.sourceBranchRemoved"
            v-gl-tooltip
            :title="ideButtonTitle"
            class="gl-display-none d-md-inline-block gl-mr-3"
            :tabindex="ideButtonTitle ? 0 : null"
          >
            <gl-button
              :href="webIdePath"
              :disabled="!mr.canPushToSourceBranch"
              class="js-web-ide"
              data-qa-selector="open_in_web_ide_button"
            >
              {{ s__('mrWidget|Open in Web IDE') }}
            </gl-button>
          </span>
          <gl-button
            v-gl-modal-directive="'modal-merge-info'"
            :disabled="mr.sourceBranchRemoved"
            class="js-check-out-branch gl-mr-3"
          >
            {{ s__('mrWidget|Check out branch') }}
          </gl-button>
          <mr-widget-how-to-merge-modal
            :is-fork="isFork"
            :can-merge="mr.canMerge"
            :source-branch="mr.sourceBranch"
            :source-project="mr.sourceProject"
            :source-project-path="mr.sourceProjectFullPath"
            :target-branch="mr.targetBranch"
            :source-project-default-url="mr.sourceProjectDefaultUrl"
            :reviewing-docs-path="mr.reviewingDocsPath"
          />
        </template>
        <gl-dropdown
          v-gl-tooltip
          :title="__('Download as')"
          :aria-label="__('Download as')"
          icon="download"
          right
          data-qa-selector="download_dropdown"
        >
          <gl-dropdown-section-header>{{ s__('Download as') }}</gl-dropdown-section-header>
          <gl-dropdown-item
            :href="mr.emailPatchesPath"
            class="js-download-email-patches"
            download
            data-qa-selector="download_email_patches_menu_item"
          >
            {{ s__('mrWidget|Email patches') }}
          </gl-dropdown-item>
          <gl-dropdown-item
            :href="mr.plainDiffPath"
            class="js-download-plain-diff"
            download
            data-qa-selector="download_plain_diff_menu_item"
          >
            {{ s__('mrWidget|Plain diff') }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>
    </div>
  </div>
</template>
