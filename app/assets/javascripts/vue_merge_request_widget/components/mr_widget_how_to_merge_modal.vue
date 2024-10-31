<script>
import { GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { escapeShellString } from '~/lib/utils/text_utility';
import { __ } from '~/locale';

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
    tip: __(
      '%{strongStart}Tip:%{strongEnd} You can also %{linkStart}check out with merge request ID%{linkEnd}.',
    ),
    title: __('Check out, review, and resolve locally'),
  },
  components: {
    GlModal,
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
      resolveConflictsFromCli: helpPagePath('topics/git/git_rebase', {
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
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="modal-merge-info"
    :title="$options.i18n.title"
    :no-enforce-focus="true"
    no-focus-on-show
    no-fade
    hide-footer
  >
    <p>
      <strong>
        {{ $options.i18n.steps.step1.label }}
      </strong>
      {{ $options.i18n.steps.step1.help }}
    </p>
    <pre
      :class="$options.userColorScheme"
      class="code highlight js-syntax-highlight gl-rounded-base"
      data-testid="how-to-merge-instructions"
      >{{ mergeInfo1 }}</pre
    >
    <p
      v-if="reviewingDocsPath"
      class="-gl-mt-4 gl-rounded-b-base gl-border-1 gl-border-solid gl-border-default gl-px-4 gl-py-3"
    >
      <gl-sprintf data-testid="docs-tip" :message="$options.i18n.tip">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #link="{ content }">
          <gl-link class="gl-inline-block" :href="reviewingDocsPath" target="_blank">{{
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
          <gl-link class="gl-inline-block" :href="resolveConflictsFromCli">
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
    <pre
      :class="$options.userColorScheme"
      class="code highlight js-syntax-highlight language-shell gl-rounded-base"
      data-testid="how-to-merge-instructions"
      >{{ mergeInfo2 }}</pre
    >
  </gl-modal>
</template>
