<script>
import { s__ } from '~/locale';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import StateContainer from '../state_container.vue';

const message = s__(
  'mrWidget|%{boldStart}Merge unavailable:%{boldEnd} merge requests are read-only on archived projects.',
);

export default {
  name: 'MRWidgetArchived',
  message,
  components: {
    BoldText,
    StateContainer,
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
    <bold-text :message="$options.message" />
  </state-container>
</template>
