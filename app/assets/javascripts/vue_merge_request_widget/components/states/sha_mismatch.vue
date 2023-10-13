<script>
import { GlButton } from '@gitlab/ui';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import { I18N_SHA_MISMATCH } from '../../i18n';
import StateContainer from '../state_container.vue';

export default {
  name: 'ShaMismatch',
  components: {
    BoldText,
    GlButton,
    StateContainer,
  },
  i18n: {
    I18N_SHA_MISMATCH,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <state-container
    status="failed"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <span
      class="gl-md-mr-3 gl-flex-grow-1 gl-ml-0! gl-text-body!"
      data-testid="head-mismatch-content"
    >
      <bold-text :message="$options.i18n.I18N_SHA_MISMATCH.warningMessage" />
    </span>
    <template #actions>
      <gl-button
        data-testid="action-button"
        size="small"
        category="primary"
        variant="confirm"
        class="gl-align-self-start"
        :href="mr.mergeRequestDiffsPath"
      >
        {{ $options.i18n.I18N_SHA_MISMATCH.actionButtonLabel }}
      </gl-button>
    </template>
  </state-container>
</template>
