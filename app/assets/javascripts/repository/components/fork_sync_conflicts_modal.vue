<script>
/* eslint-disable @gitlab/require-i18n-strings */
import { GlModal, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getBaseURL } from '~/lib/utils/url_utility';

export const i18n = {
  modalTitle: s__('ForksDivergence|Resolve merge conflicts manually'),
  modalMessage: s__(
    'ForksDivergence|The upstream changes could not be synchronized to this project due to file conflicts in the default branch. You must resolve the conflicts manually:',
  ),
  step1: __('Step 1.'),
  step2: __('Step 2.'),
  step3: __('Step 3.'),
  step4: __('Step 4.'),
  step1Text: s__(
    "ForksDivergence|Fetch the latest changes from the upstream repository's default branch:",
  ),
  step2Text: s__(
    "ForksDivergence|Check out to a branch, and merge the changes from the upstream project's default branch. You likely need to resolve conflicts during this step.",
  ),
  step3Text: s__('ForksDivergence|Push the updates to remote:'),
  copyToClipboard: __('Copy to clipboard'),
  close: __('Close'),
};

export default {
  name: 'ForkSyncConflictsModal',
  components: {
    GlModal,
    GlButton,
    ModalCopyButton,
  },
  directives: {
    SafeHtml,
  },
  props: {
    sourceDefaultBranch: {
      type: String,
      required: false,
      default: '',
    },
    sourceName: {
      type: String,
      required: false,
      default: '',
    },
    sourcePath: {
      type: String,
      required: false,
      default: '',
    },
    selectedBranch: {
      type: String,
      required: true,
      default: '',
    },
  },
  computed: {
    instructionsStep1() {
      const baseUrl = getBaseURL();
      return `git fetch ${baseUrl}${this.sourcePath} ${this.sourceDefaultBranch}`;
    },
    instructionsStep2() {
      return `git checkout ${this.selectedBranch}\ngit merge FETCH_HEAD`;
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    hide() {
      this.$refs.modal.hide();
    },
  },
  i18n,
  instructionsStep3: 'git push',
};
</script>
<template>
  <gl-modal
    ref="modal"
    modal-id="fork-sync-conflicts-modal"
    :title="$options.i18n.modalTitle"
    size="md"
  >
    <p>{{ $options.i18n.modalMessage }}</p>
    <p>
      <b> {{ $options.i18n.step1 }}</b> {{ $options.i18n.modalMessage }}
    </p>
    <div class="gl-mb-4 gl-flex">
      <pre class="gl-mb-0 gl-mr-3 gl-w-full" data-testid="resolve-conflict-instructions">{{
        instructionsStep1
      }}</pre>
      <modal-copy-button
        modal-id="fork-sync-conflicts-modal"
        :text="instructionsStep1"
        :title="$options.i18n.copyToClipboard"
        class="gl-shrink-0 !gl-bg-transparent !gl-shadow-none"
      />
    </div>
    <p>
      <b> {{ $options.i18n.step2 }}</b> {{ $options.i18n.step2Text }}
    </p>
    <div class="gl-mb-4 gl-flex">
      <pre class="gl-mb-0 gl-mr-3 gl-w-full" data-testid="resolve-conflict-instructions">{{
        instructionsStep2
      }}</pre>
      <modal-copy-button
        modal-id="fork-sync-conflicts-modal"
        :text="instructionsStep2"
        :title="$options.i18n.copyToClipboard"
        class="gl-shrink-0 !gl-bg-transparent !gl-shadow-none"
      />
    </div>
    <p>
      <b> {{ $options.i18n.step3 }}</b> {{ $options.i18n.step3Text }}
    </p>
    <div class="gl-mb-4 gl-flex">
      <pre class="gl-mb-0 gl-w-full" data-testid="resolve-conflict-instructions"
        >{{ $options.instructionsStep3 }}
</pre
      >
      <modal-copy-button
        modal-id="fork-sync-conflicts-modal"
        :text="$options.instructionsStep3"
        :title="$options.i18n.copyToClipboard"
        class="gl-ml-3 gl-shrink-0 !gl-bg-transparent !gl-shadow-none"
      />
    </div>
    <template #modal-footer>
      <gl-button @click="hide" @keydown.esc="hide">{{ $options.i18n.close }}</gl-button>
    </template>
  </gl-modal>
</template>
