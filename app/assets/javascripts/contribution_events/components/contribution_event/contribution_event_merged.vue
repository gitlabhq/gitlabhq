<script>
import { s__ } from '~/locale';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventMerged',
  i18n: {
    message: s__(
      'ContributionEvent|Accepted merge request %{targetLink} in %{resourceParentLink}.',
    ),
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
  <contribution-event-base
    :event="event"
    :message="$options.i18n.message"
    icon-name="merge-request"
  />
</template>
