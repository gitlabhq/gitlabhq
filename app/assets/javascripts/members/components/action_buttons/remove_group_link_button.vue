<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
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
  inject: ['namespace'],
  props: {
    groupLink: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions({
      showRemoveGroupLinkModal(dispatch, payload) {
        return dispatch(`${this.namespace}/showRemoveGroupLinkModal`, payload);
      },
    }),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    :title="$options.i18n.buttonTitle"
    :aria-label="$options.i18n.buttonTitle"
    icon="remove"
    data-testid="remove-group-link-button"
    @click="showRemoveGroupLinkModal(groupLink)"
  />
</template>
