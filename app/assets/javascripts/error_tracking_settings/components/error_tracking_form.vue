<script>
import { GlButton, GlFormInput } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: { GlButton, GlFormInput, Icon },
  props: {
    apiHost: {
      type: String,
      required: true,
    },
    connectError: {
      type: Boolean,
      required: true,
    },
    connectSuccessful: {
      type: Boolean,
      required: true,
    },
    token: {
      type: String,
      required: true,
    },
  },
  computed: {
    tokenInputState() {
      return this.connectError ? false : null;
    },
  },
};
</script>

<template>
  <div>
    <div class="form-group">
      <label class="label-bold" for="error-tracking-api-host">{{ __('Sentry API URL') }}</label>
      <div class="row">
        <div class="col-8 col-md-9 gl-pr-0">
          <gl-form-input
            id="error-tracking-api-host"
            :value="apiHost"
            placeholder="https://mysentryserver.com"
            @input="$emit('update-api-host', $event)"
          />
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
            @input="$emit('update-token', $event)"
          />
        </div>
        <div class="col-4 col-md-3 gl-pl-0">
          <gl-button
            class="js-error-tracking-connect prepend-left-5"
            @click="$emit('handle-connect')"
            >{{ __('Connect') }}</gl-button
          >
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
