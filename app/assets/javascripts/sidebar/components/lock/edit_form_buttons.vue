<script>
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '../../../locale';
import Flash from '~/flash';
import eventHub from '../../event_hub';
import { mapActions } from 'vuex';

export default {
  components: {
    GlLoadingIcon,
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
          const flashMessage = __(
            'Something went wrong trying to change the locked state of this %{issuableDisplayName}',
          );
          Flash(sprintf(flashMessage, { issuableDisplayName: this.issuableDisplayName }));
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
    <button type="button" class="btn btn-default gl-mr-3" @click="closeForm">
      {{ __('Cancel') }}
    </button>

    <button
      type="button"
      data-testid="lock-toggle"
      class="btn btn-close"
      :disabled="isLoading"
      @click.prevent="submitForm"
    >
      <gl-loading-icon v-if="isLoading" inline />
      {{ buttonText }}
    </button>
  </div>
</template>
