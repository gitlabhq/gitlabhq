<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
  },

  computed: {
    primaryProps() {
      return {
        text: __('Save'),
        attributes: { variant: 'confirm', category: 'primary' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit');
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="confirmSaveIntegration"
    size="sm"
    :title="s__('Integrations|Save settings?')"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="onSubmit"
  >
    <p>
      {{
        s__(
          'Integrations|Saving will update the default settings for all projects that are not using custom settings.',
        )
      }}
    </p>
    <p class="gl-mb-0">
      {{
        s__(
          'Integrations|Projects using custom settings will not be impacted unless the project owner chooses to use parent level defaults.',
        )
      }}
    </p>
  </gl-modal>
</template>
