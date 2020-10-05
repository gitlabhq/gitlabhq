<script>
import $ from 'jquery';
import { GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import { deprecatedCreateFlash as Flash } from '~/flash';
import eventHub from '../../event_hub';

export default {
  components: {
    GlButton,
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
    <gl-button class="gl-mr-3" @click="closeForm">
      {{ __('Cancel') }}
    </gl-button>
    <gl-button
      category="secondary"
      variant="warning"
      :disabled="isLoading"
      :loading="isLoading"
      data-testid="confidential-toggle"
      @click.prevent="submitForm"
    >
      {{ toggleButtonText }}
    </gl-button>
  </div>
</template>
