<script>
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import Flash from '~/flash';
import eventHub from '../../event_hub';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    fullPath: {
      required: true,
      type: String,
    },
    confidential: {
      required: true,
      type: Boolean,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    toggleButtonText() {
      if (this.isLoading) {
        return __('Applying');
      }

      return this.confidential ? __('Turn Off') : __('Turn On');
    },
  },
  methods: {
    ...mapActions(['updateConfidentialityOnIssuable']),
    closeForm() {
      eventHub.$emit('closeConfidentialityForm');
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    submitForm() {
      this.isLoading = true;
      const confidential = !this.confidential;

      this.updateConfidentialityOnIssuable({ confidential, fullPath: this.fullPath })
        .then(() => {
          eventHub.$emit('updateIssuableConfidentiality', confidential);
        })
        .catch(err => {
          Flash(
            err || __('Something went wrong trying to change the confidentiality of this issue'),
          );
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
      class="btn btn-close"
      data-testid="confidential-toggle"
      :disabled="isLoading"
      @click.prevent="submitForm"
    >
      <gl-loading-icon v-if="isLoading" inline />
      {{ toggleButtonText }}
    </button>
  </div>
</template>
