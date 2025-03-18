<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'RemoveAutopopulatedEntriesModal',
  components: {
    GlModal,
  },
  inject: ['fullPath'],
  props: {
    showModal: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {},
  computed: {
    modalOptions() {
      return {
        actionPrimary: {
          text: __('Remove entries'),
          attributes: {
            variant: 'danger',
          },
        },
        actionSecondary: {
          text: __('Cancel'),
          attributes: {
            variant: 'default',
          },
        },
      };
    },
  },
  methods: {
    hideModal() {
      this.$emit('hide');
    },
    removeEntries() {
      this.$emit('remove-entries');
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="remove-autopopulated-allowlist-entries-modal"
    :visible="showModal"
    :title="s__('CICD|Remove all auto-added allowlist entries')"
    :action-primary="modalOptions.actionPrimary"
    :action-secondary="modalOptions.actionSecondary"
    @primary.prevent="removeEntries"
    @secondary="hideModal"
    @canceled="hideModal"
    @hidden="hideModal"
  >
    <p>
      {{
        s__(
          'CICD|This action removes all groups and projects that were auto-added from the authentication log.',
        )
      }}
    </p>
    <p>
      {{
        s__('CICD|Removing these entries could cause authentication failures or disrupt pipelines.')
      }}
    </p>
  </gl-modal>
</template>
