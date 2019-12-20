<script>
import { GlButton, GlFormGroup, GlFormInput, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlLink,
    Icon,
  },
  data() {
    return { placeholderUrl: 'https://my-url.grafana.net/' };
  },
  computed: {
    ...mapState(['operationsSettingsEndpoint', 'grafanaToken', 'grafanaUrl', 'grafanaEnabled']),
    integrationEnabled: {
      get() {
        return this.grafanaEnabled;
      },
      set(grafanaEnabled) {
        this.setGrafanaEnabled(grafanaEnabled);
      },
    },
    localGrafanaToken: {
      get() {
        return this.grafanaToken;
      },
      set(token) {
        this.setGrafanaToken(token);
      },
    },
    localGrafanaUrl: {
      get() {
        return this.grafanaUrl;
      },
      set(url) {
        this.setGrafanaUrl(url);
      },
    },
  },
  methods: {
    ...mapActions([
      'setGrafanaUrl',
      'setGrafanaToken',
      'setGrafanaEnabled',
      'updateGrafanaIntegration',
    ]),
  },
};
</script>

<template>
  <section id="grafana" class="settings no-animate js-grafana-integration">
    <div class="settings-header">
      <h4 class="js-section-header">
        {{ s__('GrafanaIntegration|Grafana Authentication') }}
      </h4>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{ s__('GrafanaIntegration|Embed Grafana charts in GitLab issues.') }}
      </p>
    </div>
    <div class="settings-content">
      <form>
        <gl-form-checkbox
          id="grafana-integration-enabled"
          v-model="integrationEnabled"
          class="mb-4"
        >
          {{ s__('GrafanaIntegration|Active') }}
        </gl-form-checkbox>
        <gl-form-group
          :label="s__('GrafanaIntegration|Grafana URL')"
          label-for="grafana-url"
          :description="s__('GrafanaIntegration|Enter the base URL of the Grafana instance.')"
        >
          <gl-form-input id="grafana-url" v-model="localGrafanaUrl" :placeholder="placeholderUrl" />
        </gl-form-group>
        <gl-form-group :label="s__('GrafanaIntegration|API Token')" label-for="grafana-token">
          <gl-form-input id="grafana-token" v-model="localGrafanaToken" />
          <p class="form-text text-muted">
            {{ s__('GrafanaIntegration|Enter the Grafana API Token.') }}
            <a
              href="https://grafana.com/docs/http_api/auth/#create-api-token"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ __('More information') }}
              <icon name="external-link" class="vertical-align-middle" />
            </a>
          </p>
        </gl-form-group>
        <gl-button variant="success" @click="updateGrafanaIntegration">
          {{ __('Save Changes') }}
        </gl-button>
      </form>
    </div>
  </section>
</template>
