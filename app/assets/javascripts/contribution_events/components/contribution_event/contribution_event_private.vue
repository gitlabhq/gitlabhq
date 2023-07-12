<script>
import { s__ } from '~/locale';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventPrivate',
  i18n: {
    message: s__('ContributionEvent|Made a private contribution.'),
  },
  components: { ContributionEventBase },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" icon-name="eye-slash">{{
    $options.i18n.message
  }}</contribution-event-base>
</template>
