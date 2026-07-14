<script>
import { s__ } from '~/locale';
import { VARIANT_DEFAULT } from '../../constants';
import { isValidVariant } from '../../utils';
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
    variant: {
      type: String,
      required: false,
      default: VARIANT_DEFAULT,
      validator: isValidVariant,
    },
  },
};
</script>

<template>
  <contribution-event-base
    :event="event"
    :message="$options.i18n.message"
    :variant="variant"
    icon-name="merge-request"
  />
</template>
