<script>
import { mapActions, mapState } from 'vuex';
import {
  GlCard,
  GlForm,
  GlFormGroup,
  GlFormTextarea,
  GlButton,
  GlSprintf,
  GlAlert,
} from '@gitlab/ui';
import DashboardPanel from './dashboard_panel.vue';

const initialYml = `title: Go heap size
type: area-chart
y_axis:
  format: 'bytes'
metrics:
  - metric_id: 'go_memstats_alloc_bytes_1'
    query_range: 'go_memstats_alloc_bytes'
`;

export default {
  components: {
    GlCard,
    GlForm,
    GlFormGroup,
    GlFormTextarea,
    GlButton,
    GlSprintf,
    GlAlert,
    DashboardPanel,
  },
  data() {
    return {
      yml: initialYml,
    };
  },
  computed: {
    ...mapState('monitoringDashboard', [
      'panelPreviewIsLoading',
      'panelPreviewError',
      'panelPreviewGraphData',
      'projectPath',
      'addDashboardDocumentationPath',
    ]),
  },
  methods: {
    ...mapActions('monitoringDashboard', ['fetchPanelPreview']),
    onSubmit() {
      this.fetchPanelPreview(this.yml);
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-mx-n3">
      <gl-card class="gl-flex-grow-1 gl-flex-basis-0 gl-mx-3">
        <template #header>
          <h2 class="gl-font-size-h2 gl-my-3">{{ s__('Metrics|1. Define and preview panel') }}</h2>
        </template>
        <template #default>
          <p>{{ s__('Metrics|Define panel YAML below to preview panel.') }}</p>
          <gl-form @submit.prevent="onSubmit">
            <gl-form-group :label="s__('Metrics|Panel YAML')" label-for="panel-yml-input">
              <gl-form-textarea
                id="panel-yml-input"
                v-model="yml"
                class="gl-h-200! gl-font-monospace! gl-font-size-monospace!"
              />
            </gl-form-group>
            <div class="gl-text-right">
              <gl-button
                ref="clipboardCopyBtn"
                variant="success"
                category="secondary"
                :data-clipboard-text="yml"
                @click="$toast.show(s__('Metrics|Panel YAML copied'))"
              >
                {{ s__('Metrics|Copy YAML') }}
              </gl-button>
              <gl-button
                type="submit"
                variant="success"
                :disabled="panelPreviewIsLoading"
                class="js-no-auto-disable"
              >
                {{ s__('Metrics|Preview panel') }}
              </gl-button>
            </div>
          </gl-form>
        </template>
      </gl-card>

      <gl-card
        class="gl-flex-grow-1 gl-flex-basis-0 gl-mx-3"
        body-class="gl-display-flex gl-flex-direction-column"
      >
        <template #header>
          <h2 class="gl-font-size-h2 gl-my-3">
            {{ s__('Metrics|2. Paste panel YAML into dashboard') }}
          </h2>
        </template>
        <template #default>
          <div
            class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-justify-content-center"
          >
            <p>
              {{ s__('Metrics|Copy and paste the panel YAML into your dashboard YAML file.') }}
              <br />
              <gl-sprintf
                :message="
                  s__(
                    'Metrics|Dashboard files can be found in %{codeStart}.gitlab/dashboards%{codeEnd} at the root of this project.',
                  )
                "
              >
                <template #code="{content}">
                  <code>{{ content }}</code>
                </template>
              </gl-sprintf>
            </p>
          </div>

          <div class="gl-text-right">
            <gl-button
              ref="viewDocumentationBtn"
              category="secondary"
              variant="info"
              target="_blank"
              :href="addDashboardDocumentationPath"
            >
              {{ s__('Metrics|View documentation') }}
            </gl-button>
            <gl-button ref="openRepositoryBtn" variant="success" :href="projectPath">
              {{ s__('Metrics|Open repository') }}
            </gl-button>
          </div>
        </template>
      </gl-card>
    </div>

    <gl-alert v-if="panelPreviewError" variant="warning" :dismissible="false">
      {{ panelPreviewError }}
    </gl-alert>

    <dashboard-panel :graph-data="panelPreviewGraphData" />
  </div>
</template>
