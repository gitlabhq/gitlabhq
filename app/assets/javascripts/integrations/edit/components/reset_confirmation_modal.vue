<script>
import { GlModal } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  components: {
    GlModal,
  },
  primaryProps: {
    text: __('Reset'),
    attributes: { variant: 'danger', category: 'primary' },
  },
  cancelProps: {
    text: __('Cancel'),
  },
  methods: {
    onReset() {
      this.$emit('reset');
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="confirmResetIntegration"
    size="sm"
    :title="s__('Integrations|Reset integration?')"
    :action-primary="$options.primaryProps"
    :action-cancel="$options.cancelProps"
    @primary="onReset"
  >
    <p>
      {{
        s__(
          'Integrations|Resetting this integration will clear the settings and deactivate this integration.',
        )
      }}
    </p>
    <p>
      {{ s__('Integrations|All projects inheriting these settings will also be reset.') }}
    </p>

    <p class="gl-mb-0">
      {{ s__('Integrations|Projects using custom settings will not be affected.') }}
    </p>
  </gl-modal>
</template>
