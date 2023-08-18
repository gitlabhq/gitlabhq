<script>
import { GlButton } from '@gitlab/ui';
import $ from 'jquery';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import eventHub from '../../event_hub';

export default {
  components: {
    GlButton,
  },
  inject: ['fullPath'],
  props: {
    isLocked: {
      required: true,
      type: Boolean,
    },
    issuableDisplayName: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    buttonText() {
      if (this.isLoading) {
        return __('Applying');
      }

      return this.isLocked ? __('Unlock') : __('Lock');
    },
  },
  methods: {
    ...mapActions(['updateLockedAttribute']),
    closeForm() {
      eventHub.$emit('closeLockForm');
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    submitForm() {
      this.isLoading = true;

      this.updateLockedAttribute({
        locked: !this.isLocked,
        fullPath: this.fullPath,
      })
        .catch(() => {
          const alertMessage = __(
            'Something went wrong trying to change the locked state of this %{issuableDisplayName}',
          );
          createAlert({
            message: sprintf(alertMessage, { issuableDisplayName: this.issuableDisplayName }),
          });
        })
        .finally(() => {
          this.closeForm();
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div class="sidebar-item-warning-message-actions">
    <gl-button class="gl-mr-3" @click="closeForm">
      {{ __('Cancel') }}
    </gl-button>

    <gl-button
      data-testid="lock-toggle"
      category="secondary"
      variant="confirm"
      :disabled="isLoading"
      :loading="isLoading"
      @click.prevent="submitForm"
    >
      {{ buttonText }}
    </gl-button>
  </div>
</template>
