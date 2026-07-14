<script>
import { s__ } from '~/locale';
import { VARIANT_DEFAULT } from '../../constants';
import { isValidVariant } from '../../utils';
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
  <contribution-event-base :event="event" :variant="variant" icon-name="eye-slash">{{
    $options.i18n.message
  }}</contribution-event-base>
</template>
