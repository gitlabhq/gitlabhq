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
  <state-container status="failed" is-collapsible>
    <span class="!gl-ml-0 gl-grow !gl-text-default md:gl-mr-3" data-testid="head-mismatch-content">
      <bold-text :message="$options.i18n.I18N_SHA_MISMATCH.warningMessage" />
    </span>
    <template #actions>
      <gl-button
        data-testid="action-button"
        size="small"
        category="primary"
        variant="confirm"
        class="gl-self-start"
        :href="mr.mergeRequestDiffsPath"
      >
        {{ $options.i18n.I18N_SHA_MISMATCH.actionButtonLabel }}
      </gl-button>
    </template>
  </state-container>
</template>
