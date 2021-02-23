<script>
/* eslint-disable @gitlab/require-i18n-strings */
import { GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  i18n: {
    steps: {
      step1: {
        label: __('Step 1.'),
        help: __('Fetch and check out the branch for this merge request'),
      },
      step2: {
        label: __('Step 2.'),
        help: __('Review the changes locally'),
      },
      step3: {
        label: __('Step 3.'),
        help: __('Merge the branch and fix any conflicts that come up'),
      },
      step4: {
        label: __('Step 4.'),
        help: __('Push the result of the merge to GitLab'),
      },
    },
    copyCommands: __('Copy commands'),
    tip: __(
      '%{strongStart}Tip:%{strongEnd} You can also checkout merge requests locally by %{linkStart}following these guidelines%{linkEnd}',
    ),
    title: __('Check out, review, and merge locally'),
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
  computed: {
    mergeInfo1() {
      return this.isFork
        ? `git fetch "${this.sourceProjectDefaultUrl}" ${this.sourceBranch}\ngit checkout -b "${this.sourceProjectPath}-${this.sourceBranch}" FETCH_HEAD`
        : `git fetch origin\ngit checkout -b "${this.sourceBranch}" "origin/${this.sourceBranch}"`;
    },
    mergeInfo2() {
      return this.isFork
        ? `git fetch origin\ngit checkout "${this.targetBranch}"\ngit merge --no-ff "${this.sourceProjectPath}-${this.sourceBranch}"`
        : `git fetch origin\ngit checkout "${this.targetBranch}"\ngit merge --no-ff "${this.sourceBranch}"`;
    },
    mergeInfo3() {
      return this.canMerge
        ? `git push origin "${this.targetBranch}"`
        : __('Note that pushing to GitLab requires write access to this repository.');
    },
  },
};
</script>

<template>
  <gl-modal
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
      {{ $options.i18n.steps.step3.help }}
    </p>
    <div class="gl-display-flex">
      <pre class="gl-w-full" data-testid="how-to-merge-instructions">{{ mergeInfo2 }}</pre>
      <clipboard-button
        :text="mergeInfo2"
        :title="$options.i18n.copyCommands"
        class="gl-shadow-none! gl-bg-transparent! gl-flex-shrink-0"
      />
    </div>
    <p>
      <strong>
        {{ $options.i18n.steps.step4.label }}
      </strong>
      {{ $options.i18n.steps.step4.help }}
    </p>
    <div class="gl-display-flex">
      <pre class="gl-w-full" data-testid="how-to-merge-instructions">{{ mergeInfo3 }}</pre>
      <clipboard-button
        :text="mergeInfo3"
        :title="$options.i18n.copyCommands"
        class="gl-shadow-none! gl-bg-transparent! gl-flex-shrink-0"
      />
    </div>
    <p v-if="reviewingDocsPath">
      <gl-sprintf :message="$options.i18n.tip">
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
  </gl-modal>
</template>
