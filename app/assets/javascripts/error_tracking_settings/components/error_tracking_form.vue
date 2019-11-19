<script>
import { mapActions, mapState } from 'vuex';
import { GlFormInput } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

export default {
  components: { GlFormInput, Icon, LoadingButton },
  computed: {
    ...mapState(['apiHost', 'connectError', 'connectSuccessful', 'isLoadingProjects', 'token']),
    tokenInputState() {
      return this.connectError ? false : null;
    },
  },
  methods: {
    ...mapActions(['fetchProjects', 'updateApiHost', 'updateToken']),
  },
};
</script>

<template>
  <div>
    <div class="form-group">
      <label class="label-bold" for="error-tracking-api-host">{{ __('Sentry API URL') }}</label>
      <div class="row">
        <div class="col-8 col-md-9 gl-pr-0">
          <!-- eslint-disable @gitlab/vue-i18n/no-bare-attribute-strings -->
          <gl-form-input
            id="error-tracking-api-host"
            :value="apiHost"
            :disabled="isLoadingProjects"
            placeholder="https://mysentryserver.com"
            @input="updateApiHost"
          />
          <!-- eslint-enable @gitlab/vue-i18n/no-bare-attribute-strings -->
        </div>
      </div>
      <p class="form-text text-muted">
        {{ s__('ErrorTracking|Find your hostname in your Sentry account settings page') }}
      </p>
    </div>
    <div class="form-group" :class="{ 'gl-show-field-errors': connectError }">
      <label class="label-bold" for="error-tracking-token">
        {{ s__('ErrorTracking|Auth Token') }}
      </label>
      <div class="row">
        <div class="col-8 col-md-9 gl-pr-0">
          <gl-form-input
            id="error-tracking-token"
            :value="token"
            :state="tokenInputState"
            :disabled="isLoadingProjects"
            @input="updateToken"
          />
        </div>
        <div class="col-4 col-md-3 gl-pl-0">
          <loading-button
            class="js-error-tracking-connect prepend-left-5 d-inline-flex"
            :label="isLoadingProjects ? __('Connecting') : __('Connect')"
            :loading="isLoadingProjects"
            @click="fetchProjects"
          />
          <icon
            v-show="connectSuccessful"
            class="js-error-tracking-connect-success prepend-left-5 text-success align-middle"
            :aria-label="__('Projects Successfully Retrieved')"
            name="check-circle"
          />
        </div>
      </div>
      <p v-if="connectError" class="gl-field-error">
        {{ s__('ErrorTracking|Connection has failed. Re-check Auth Token and try again.') }}
      </p>
      <p v-else class="form-text text-muted">
        {{
          s__(
            "ErrorTracking|After adding your Auth Token, use the 'Connect' button to load projects",
          )
        }}
      </p>
    </div>
  </div>
</template>
