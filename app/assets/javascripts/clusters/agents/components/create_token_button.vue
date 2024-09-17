<script>
import { GlButton, GlModalDirective, GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import { CREATE_TOKEN_MODAL } from '../constants';

export default {
  components: {
    GlButton,
    GlTooltip,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['canAdminCluster'],
  modalId: CREATE_TOKEN_MODAL,
  i18n: {
    createTokenButton: s__('ClusterAgents|Create token'),
    dropdownDisabledHint: s__(
      'ClusterAgents|Requires a Maintainer or greater role to perform these actions',
    ),
  },
};
</script>

<template>
  <div>
    <div ref="addToken" class="gl-inline-block">
      <gl-button
        v-gl-modal-directive="$options.modalId"
        :disabled="!canAdminCluster"
        category="primary"
        variant="confirm"
        >{{ $options.i18n.createTokenButton }}
      </gl-button>

      <gl-tooltip
        v-if="!canAdminCluster"
        :target="() => $refs.addToken"
        :title="$options.i18n.dropdownDisabledHint"
      />
    </div>
  </div>
</template>
