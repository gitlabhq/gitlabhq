<script>
import {
  GlLink,
  GlTooltipDirective,
  GlModalDirective,
  GlSafeHtmlDirective as SafeHtml,
  GlSprintf,
} from '@gitlab/ui';
import { constructWebIDEPath } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import clipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import MrWidgetIcon from './mr_widget_icon.vue';

export default {
  name: 'MRWidgetHeader',
  components: {
    clipboardButton,
    TooltipOnTruncate,
    MrWidgetIcon,
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
      return constructWebIDEPath(this.mr);
    },
    isFork() {
      return this.mr.sourceProjectFullPath !== this.mr.targetProjectFullPath;
    },
  },
  i18n: {
    webIdeText: s__('mrWidget|Open in Web IDE'),
    gitpodText: s__('mrWidget|Open in Gitpod'),
  },
};
</script>
<template>
  <div class="gl-display-flex mr-source-target">
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
    </div>
  </div>
</template>
