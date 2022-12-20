<script>
import { GlButton, GlCard, GlSprintf, GlIcon, GlLink } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import {
  STARTER_TEMPLATE_NAME,
  RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
  RUNNERS_SETTINGS_LINK_CLICKED_EVENT,
  RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT,
  RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT,
  I18N,
} from '~/ci/pipeline_editor/constants';
import Tracking from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import { isExperimentVariant } from '~/experimentation/utils';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import CiTemplates from './ci_templates.vue';

export default {
  components: {
    GlButton,
    GlCard,
    GlSprintf,
    GlIcon,
    GlLink,
    GitlabExperiment,
    CiTemplates,
  },
  mixins: [Tracking.mixin()],
  STARTER_TEMPLATE_NAME,
  RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
  RUNNERS_SETTINGS_LINK_CLICKED_EVENT,
  RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT,
  RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT,
  I18N,
  inject: ['anyRunnersAvailable', 'pipelineEditorPath', 'ciRunnerSettingsPath'],
  data() {
    return {
      gettingStartedTemplateUrl: mergeUrlParams(
        { template: STARTER_TEMPLATE_NAME },
        this.pipelineEditorPath,
      ),
      tracker: null,
    };
  },
  computed: {
    sharedRunnersHelpPagePath() {
      return helpPagePath('ci/runners/runners_scope', { anchor: 'shared-runners' });
    },
    runnersAvailabilitySectionExperimentEnabled() {
      return isExperimentVariant(RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME);
    },
  },
  created() {
    this.tracker = new ExperimentTracking(RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME);
  },
  methods: {
    trackEvent(template) {
      this.track('template_clicked', {
        label: template,
      });
    },
    trackExperimentEvent(action) {
      this.tracker.event(action);
    },
  },
};
</script>
<template>
  <div>
    <h2 class="gl-font-size-h2 gl-text-gray-900">{{ $options.I18N.title }}</h2>

    <gitlab-experiment :name="$options.RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME">
      <template #candidate>
        <div v-if="anyRunnersAvailable">
          <h2 class="gl-font-base gl-text-gray-900">
            <gl-icon name="check-circle-filled" class="gl-text-green-500 gl-mr-2" :size="12" />
            {{ $options.I18N.runners.title }}
          </h2>
          <p class="gl-text-gray-800 gl-mb-6">
            <gl-sprintf :message="$options.I18N.runners.subtitle">
              <template #settingsLink="{ content }">
                <gl-link
                  data-testid="settings-link"
                  :href="ciRunnerSettingsPath"
                  @click="trackExperimentEvent($options.RUNNERS_SETTINGS_LINK_CLICKED_EVENT)"
                  >{{ content }}</gl-link
                >
              </template>
              <template #docsLink="{ content }">
                <gl-link
                  data-testid="documentation-link"
                  :href="sharedRunnersHelpPagePath"
                  @click="trackExperimentEvent($options.RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT)"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </p>
        </div>

        <div v-else>
          <h2 class="gl-font-base gl-text-gray-900">
            <gl-icon name="warning-solid" class="gl-text-red-600 gl-mr-2" :size="14" />
            {{ $options.I18N.noRunners.title }}
          </h2>
          <p class="gl-text-gray-800 gl-mb-6">{{ $options.I18N.noRunners.subtitle }}</p>
          <gl-button
            data-testid="settings-button"
            category="primary"
            variant="confirm"
            :href="ciRunnerSettingsPath"
            @click="trackExperimentEvent($options.RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT)"
          >
            {{ $options.I18N.noRunners.cta }}
          </gl-button>
        </div>
      </template>
    </gitlab-experiment>

    <template v-if="!runnersAvailabilitySectionExperimentEnabled || anyRunnersAvailable">
      <h2 class="gl-font-lg gl-text-gray-900">{{ $options.I18N.learnBasics.title }}</h2>
      <p class="gl-text-gray-800 gl-mb-6">
        <gl-sprintf :message="$options.I18N.learnBasics.subtitle">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>

      <div class="gl-lg-w-25p gl-lg-pr-5 gl-mb-8">
        <gl-card>
          <div class="gl-flex-direction-row">
            <div class="gl-py-5"><gl-emoji class="gl-font-size-h2-xl" data-name="wave" /></div>
            <div class="gl-mb-3">
              <strong class="gl-text-gray-800 gl-mb-2">
                {{ $options.I18N.learnBasics.gettingStarted.title }}
              </strong>
            </div>
            <p class="gl-font-sm">{{ $options.I18N.learnBasics.gettingStarted.description }}</p>
          </div>

          <gl-button
            category="primary"
            variant="confirm"
            :href="gettingStartedTemplateUrl"
            data-testid="test-template-link"
            @click="trackEvent($options.STARTER_TEMPLATE_NAME)"
          >
            {{ $options.I18N.learnBasics.gettingStarted.cta }}
          </gl-button>
        </gl-card>
      </div>

      <h2 class="gl-font-lg gl-text-gray-900">{{ $options.I18N.templates.title }}</h2>
      <p class="gl-text-gray-800 gl-mb-6">{{ $options.I18N.templates.subtitle }}</p>

      <ci-templates />
    </template>
  </div>
</template>
