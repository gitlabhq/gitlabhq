<script>
import { GlBadge, GlFriendlyWrap, GlLink, GlModal, GlTooltipDirective } from '@gitlab/ui';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { __, n__, s__, sprintf } from '~/locale';
import CodeBlock from '~/vue_shared/components/code_block.vue';

export default {
  name: 'TestCaseDetails',
  components: {
    CodeBlock,
    GlBadge,
    GlFriendlyWrap,
    GlLink,
    GlModal,
    ModalCopyButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    testCase: {
      type: Object,
      required: false,
      default: () => {
        return {};
      },
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    failureHistoryMessage() {
      if (!this.hasRecentFailures) {
        return null;
      }

      return sprintf(
        n__(
          'Reports|Failed %{count} time in %{baseBranch} in the last 14 days',
          'Reports|Failed %{count} times in %{baseBranch} in the last 14 days',
          this.recentFailures.count,
        ),
        {
          count: this.recentFailures.count,
          baseBranch: this.recentFailures.base_branch,
        },
      );
    },
    hasRecentFailures() {
      return Boolean(this.recentFailures);
    },
    recentFailures() {
      return this.testCase.recent_failures;
    },
  },
  text: {
    name: __('Name'),
    file: __('File'),
    duration: __('Execution time'),
    history: __('History'),
    trace: __('System output'),
    attachment: s__('TestReports|Attachment'),
    copyTestName: s__('TestReports|Copy test name to rerun locally'),
  },
  modalCloseButton: {
    text: __('Close'),
    attributes: { variant: 'confirm' },
  },
};
</script>

<template>
  <gl-modal
    data-testid="test-case-details-modal"
    :modal-id="modalId"
    :title="testCase.classname"
    :action-primary="$options.modalCloseButton"
    :visible="visible"
    @hidden="$emit('hidden')"
  >
    <div class="-gl-mx-4 gl-my-3 gl-flex gl-flex-wrap">
      <strong class="col-sm-3">{{ $options.text.name }}</strong>
      <div class="col-sm-9" data-testid="test-case-name">
        {{ testCase.name }}
      </div>
    </div>

    <div v-if="testCase.file" class="-gl-mx-4 gl-my-3 gl-flex gl-flex-wrap">
      <strong class="col-sm-3">{{ $options.text.file }}</strong>
      <div class="col-sm-9" data-testid="test-case-file">
        <gl-link v-if="testCase.filePath" class="gl-break-words" :href="testCase.filePath">
          {{ testCase.file }}
        </gl-link>
        <span v-else>{{ testCase.file }}</span>
        <modal-copy-button
          :title="$options.text.copyTestName"
          :text="testCase.file"
          :modal-id="modalId"
          category="tertiary"
          class="gl-ml-1"
        />
      </div>
    </div>

    <div class="-gl-mx-4 gl-my-3 gl-flex gl-flex-wrap">
      <strong class="col-sm-3">{{ $options.text.duration }}</strong>
      <div v-if="testCase.formattedTime" class="col-sm-9" data-testid="test-case-duration">
        {{ testCase.formattedTime }}
      </div>
      <div v-else-if="testCase.execution_time" class="col-sm-9" data-testid="test-case-duration">
        {{ sprintf('%{value} s', { value: testCase.execution_time }) }}
      </div>
    </div>

    <div v-if="testCase.recent_failures" class="-gl-mx-4 gl-my-3 gl-flex gl-flex-wrap">
      <strong class="col-sm-3">{{ $options.text.history }}</strong>
      <div class="col-sm-9" data-testid="test-case-recent-failures">
        <gl-badge variant="warning">{{ failureHistoryMessage }}</gl-badge>
      </div>
    </div>

    <div v-if="testCase.attachment_url" class="-gl-mx-4 gl-my-3 gl-flex gl-flex-wrap">
      <strong class="col-sm-3">{{ $options.text.attachment }}</strong>
      <gl-link
        class="col-sm-9"
        :href="testCase.attachment_url"
        target="_blank"
        data-testid="test-case-attachment-url"
      >
        <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="testCase.attachment_url" />
      </gl-link>
    </div>

    <div
      v-if="testCase.system_output"
      class="-gl-mx-4 gl-my-3 gl-flex gl-flex-wrap"
      data-testid="test-case-trace"
    >
      <strong class="col-sm-3 gl-mb-2">{{ $options.text.trace }}</strong>
      <code-block class="gl-p-4" :code="testCase.system_output" />
    </div>
  </gl-modal>
</template>
