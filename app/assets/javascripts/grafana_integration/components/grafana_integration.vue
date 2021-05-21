<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlFormCheckbox,
  GlIcon,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  data() {
    return {
      helpUrl: helpPagePath('operations/metrics/embed_grafana', {
        anchor: 'use-integration-with-grafana-api',
      }),
      placeholderUrl: 'https://my-grafana.example.com/',
    };
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
      <h4
        class="js-section-header settings-title js-settings-toggle js-settings-toggle-trigger-only"
      >
        {{ s__('GrafanaIntegration|Grafana authentication') }}
      </h4>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{
          s__(
            'GrafanaIntegration|Set up Grafana authentication to embed Grafana panels in GitLab Flavored Markdown.',
          )
        }}
        <gl-link :href="helpUrl">{{ __('Learn more.') }}</gl-link>
      </p>
    </div>
    <div class="settings-content">
      <form>
        <gl-form-group :label="__('Enable authentication')" label-for="grafana-integration-enabled">
          <gl-form-checkbox id="grafana-integration-enabled" v-model="integrationEnabled">
            {{ s__('GrafanaIntegration|Active') }}
          </gl-form-checkbox>
        </gl-form-group>
        <gl-form-group
          :label="s__('GrafanaIntegration|Grafana URL')"
          label-for="grafana-url"
          :description="s__('GrafanaIntegration|Enter the base URL of the Grafana instance.')"
        >
          <gl-form-input id="grafana-url" v-model="localGrafanaUrl" :placeholder="placeholderUrl" />
        </gl-form-group>
        <gl-form-group :label="s__('GrafanaIntegration|API token')" label-for="grafana-token">
          <gl-form-input id="grafana-token" v-model="localGrafanaToken" />
          <p class="form-text text-muted">
            <gl-sprintf
              :message="
                s__('GrafanaIntegration|Enter the %{docLinkStart}Grafana API token%{docLinkEnd}.')
              "
            >
              <template #docLink="{ content }">
                <gl-link
                  href="https://grafana.com/docs/http_api/auth/#create-api-token"
                  target="_blank"
                  >{{ content }} <gl-icon name="external-link" class="gl-vertical-align-middle"
                /></gl-link>
              </template>
            </gl-sprintf>
          </p>
        </gl-form-group>
        <gl-button
          variant="confirm"
          category="primary"
          data-testid="save-grafana-settings-button"
          @click="updateGrafanaIntegration"
        >
          {{ __('Save changes') }}
        </gl-button>
      </form>
    </div>
  </section>
</template>
