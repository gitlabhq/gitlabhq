<script>
import { mapActions } from 'vuex';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'RemoveGroupLinkButton',
  i18n: {
    buttonTitle: s__('Members|Remove group'),
  },
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    groupLink: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions(['showRemoveGroupLinkModal']),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    variant="danger"
    :title="$options.i18n.buttonTitle"
    :aria-label="$options.i18n.buttonTitle"
    icon="remove"
    @click="showRemoveGroupLinkModal(groupLink)"
  />
</template>
