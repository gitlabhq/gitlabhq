<script>
import { GlFormInput, GlIcon, GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

export default {
  components: { GlFormInput, GlIcon, GlButton },
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
          <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
          <gl-form-input
            id="error-tracking-api-host"
            :value="apiHost"
            :disabled="isLoadingProjects"
            placeholder="https://mysentryserver.com"
            @input="updateApiHost"
          />
          <p class="form-text text-muted">
            {{
              s__(
                "ErrorTracking|If you self-host Sentry, enter your Sentry instance's full URL. If you use Sentry's hosted solution, enter https://sentry.io",
              )
            }}
          </p>
          <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
        </div>
      </div>
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
          <gl-button
            class="js-error-tracking-connect gl-ml-2 d-inline-flex"
            category="secondary"
            variant="default"
            :loading="isLoadingProjects"
            @click="fetchProjects"
          >
            {{ isLoadingProjects ? __('Connecting') : __('Connect') }}
          </gl-button>

          <gl-icon
            v-show="connectSuccessful"
            class="js-error-tracking-connect-success gl-ml-2 text-success align-middle"
            :aria-label="__('Projects Successfully Retrieved')"
            name="check"
          />
        </div>
      </div>
      <p v-if="connectError" class="gl-field-error">
        {{ s__('ErrorTracking|Connection failed. Check Auth Token and try again.') }}
      </p>
      <p v-else class="form-text text-muted">
        {{
          s__(
            'ErrorTracking|After adding your Auth Token, select the Connect button to load projects.',
          )
        }}
      </p>
    </div>
  </div>
</template>
