<script>
import { GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { escapeShellString } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  i18n: {
    steps: {
      step1: {
        label: __('Step 1.'),
        help: __("Fetch and check out this merge request's feature branch:"),
      },
      step2: {
        label: __('Step 2.'),
        help: __('Review the changes locally.'),
      },
      step3: {
        label: __('Step 3.'),
        help: __('Resolve any conflicts. %{linkStart}How do I fix them?%{linkEnd}'),
      },
      step4: {
        label: __('Step 4.'),
        help: __('Push the source branch up to GitLab.'),
      },
    },
    copyCommands: __('Copy commands'),
    tip: __(
      '%{strongStart}Tip:%{strongEnd} You can also %{linkStart}check out with merge request ID%{linkEnd}.',
    ),
    title: __('Check out, review, and resolve locally'),
  },
  components: {
    GlModal,
    ClipboardButton,
    GlLink,
    GlSprintf,
  },
  props: {
    canMerge: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFork: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceBranch: {
      type: String,
      required: false,
      default: '',
    },
    sourceProjectPath: {
      type: String,
      required: false,
      default: '',
    },
    targetBranch: {
      type: String,
      required: false,
      default: '',
    },
    sourceProjectDefaultUrl: {
      type: String,
      required: false,
      default: '',
    },
    reviewingDocsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      resolveConflictsFromCli: helpPagePath('user/project/merge_requests/conflicts', {
        anchor: 'resolve-conflicts-from-the-command-line',
      }),
    };
  },
  computed: {
    mergeInfo1() {
      const escapedOriginBranch = escapeShellString(`origin/${this.sourceBranch}`);

      return this.isFork
        ? `git fetch "${this.sourceProjectDefaultUrl}" ${this.escapedSourceBranch}\ngit checkout -b ${this.escapedForkBranch} FETCH_HEAD` // eslint-disable-line @gitlab/require-i18n-strings
        : `git fetch origin\ngit checkout -b ${this.escapedSourceBranch} ${escapedOriginBranch}`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    mergeInfo2() {
      return this.isFork
        ? `git push "${this.sourceProjectDefaultUrl}" ${this.escapedForkPushBranch}` // eslint-disable-line @gitlab/require-i18n-strings
        : `git push origin ${this.escapedSourceBranch}`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    escapedForkBranch() {
      return escapeShellString(`${this.sourceProjectPath}-${this.sourceBranch}`);
    },
    escapedForkPushBranch() {
      return escapeShellString(
        `${this.sourceProjectPath}-${this.sourceBranch}:${this.sourceBranch}`,
      );
    },
    escapedSourceBranch() {
      return escapeShellString(this.sourceBranch);
    },
  },
  mounted() {
    document.addEventListener('click', (e) => {
      if (e.target.closest('.js-check-out-modal-trigger')) {
        this.$refs.modal.show();
      }
    });
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="modal-merge-info"
    :no-enforce-focus="true"
    :title="$options.i18n.title"
    no-fade
    hide-footer
  >
    <p>
      <strong>
        {{ $options.i18n.steps.step1.label }}
      </strong>
      {{ $options.i18n.steps.step1.help }}
    </p>
    <div class="gl-display-flex">
      <pre class="gl-w-full" data-testid="how-to-merge-instructions">{{ mergeInfo1 }}</pre>
      <clipboard-button
        :text="mergeInfo1"
        :title="$options.i18n.copyCommands"
        class="gl-shadow-none! gl-bg-transparent! gl-flex-shrink-0"
      />
    </div>
    <p v-if="reviewingDocsPath">
      <gl-sprintf data-testid="docs-tip" :message="$options.i18n.tip">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #link="{ content }">
          <gl-link class="gl-display-inline-block" :href="reviewingDocsPath" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <p>
      <strong>
        {{ $options.i18n.steps.step2.label }}
      </strong>
      {{ $options.i18n.steps.step2.help }}
    </p>
    <p>
      <strong>
        {{ $options.i18n.steps.step3.label }}
      </strong>
      <gl-sprintf :message="$options.i18n.steps.step3.help">
        <template #link="{ content }">
          <gl-link class="gl-display-inline-block" :href="resolveConflictsFromCli">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <strong>
        {{ $options.i18n.steps.step4.label }}
      </strong>
      {{ $options.i18n.steps.step4.help }}
    </p>
    <div class="gl-display-flex">
      <pre class="gl-w-full" data-testid="how-to-merge-instructions">{{ mergeInfo2 }}</pre>
      <clipboard-button
        :text="mergeInfo2"
        :title="$options.i18n.copyCommands"
        class="gl-shadow-none! gl-bg-transparent! gl-flex-shrink-0"
      />
    </div>
  </gl-modal>
</template>
