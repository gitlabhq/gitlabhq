<script>
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Flash from '~/flash';
import eventHub from '../../event_hub';

export default {
  components: {
    GlLoadingIcon,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    fullPath: {
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
    ...mapState({ confidential: ({ noteableData }) => noteableData.confidential }),
    toggleButtonText() {
      if (this.isLoading) {
        return __('Applying');
      }

      return this.confidential ? __('Turn Off') : __('Turn On');
    },
  },
  methods: {
    ...mapActions(['updateConfidentialityOnIssue']),
    closeForm() {
      eventHub.$emit('closeConfidentialityForm');
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    submitForm() {
      this.isLoading = true;
      const confidential = !this.confidential;

      if (this.glFeatures.confidentialApolloSidebar) {
        this.updateConfidentialityOnIssue({ confidential, fullPath: this.fullPath })
          .catch(() => {
            Flash(__('Something went wrong trying to change the confidentiality of this issue'));
          })
          .finally(() => {
            this.closeForm();
            this.isLoading = false;
          });
      } else {
        eventHub.$emit('updateConfidentialAttribute');
      }
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
