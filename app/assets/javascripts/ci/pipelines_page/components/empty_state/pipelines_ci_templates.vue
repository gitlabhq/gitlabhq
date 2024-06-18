<script>
import { GlButton, GlCard, GlSprintf } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import {
  STARTER_TEMPLATE_NAME,
  I18N,
  MIGRATION_PLAN_HELP_PATH,
  MIGRATE_FROM_JENKINS_TRACKING_LABEL,
} from '~/ci/pipeline_editor/constants';
import Tracking from '~/tracking';
import CiTemplates from './ci_templates.vue';

export default {
  components: {
    GlButton,
    GlCard,
    GlSprintf,
    CiTemplates,
  },
  mixins: [Tracking.mixin()],
  STARTER_TEMPLATE_NAME,
  I18N,
  inject: ['pipelineEditorPath', 'showJenkinsCiPrompt'],
  data() {
    return {
      gettingStartedTemplateUrl: mergeUrlParams(
        { template: STARTER_TEMPLATE_NAME },
        this.pipelineEditorPath,
      ),
      tracker: null,
      migrationPlanUrl: MIGRATION_PLAN_HELP_PATH,
      migrationPromptTrackingLabel: MIGRATE_FROM_JENKINS_TRACKING_LABEL,
    };
  },
  mounted() {
    if (this.showJenkinsCiPrompt) {
      this.trackEvent('render', this.migrationPromptTrackingLabel);
    }
  },
  methods: {
    trackEvent(action, label) {
      this.track(action, { label });
    },
  },
};
</script>

<template>
  <div>
    <h2 class="gl-font-size-h2 gl-text-gray-900">{{ $options.I18N.title }}</h2>

    <h2 class="gl-font-lg gl-text-gray-900">{{ $options.I18N.learnBasics.title }}</h2>
    <p class="gl-text-gray-800 gl-mb-6">
      <gl-sprintf :message="$options.I18N.learnBasics.subtitle">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>

    <div class="gl-display-flex gl-flex-direction-row gl-flex-wrap">
      <div
        v-if="showJenkinsCiPrompt"
        class="gl-lg-w-25p gl-md-w-half gl-w-full gl-md-pr-5 gl-pb-8"
        data-testid="migrate-from-jenkins-prompt"
      >
        <gl-card class="gl-bg-blue-50">
          <div class="gl-flex-direction-row">
            <div class="gl-py-5"><gl-emoji class="gl-text-size-h2-xl" data-name="rocket" /></div>
            <div class="gl-mb-3">
              <strong class="gl-text-gray-800 gl-mb-2">{{
                $options.I18N.learnBasics.migrateFromJenkins.title
              }}</strong>
            </div>
            <p class="gl-font-sm gl-h-13">
              {{ $options.I18N.learnBasics.migrateFromJenkins.description }}
            </p>
          </div>

          <gl-button
            category="primary"
            variant="confirm"
            :href="migrationPlanUrl"
            target="_blank"
            @click="trackEvent('template_clicked', migrationPromptTrackingLabel)"
          >
            {{ $options.I18N.learnBasics.migrateFromJenkins.cta }}
          </gl-button>
        </gl-card>
      </div>

      <div class="gl-lg-w-25p gl-md-w-half gl-w-full gl-pb-8">
        <gl-card>
          <div class="gl-flex-direction-row">
            <div class="gl-py-5"><gl-emoji class="gl-text-size-h2-xl" data-name="wave" /></div>
            <div class="gl-mb-3">
              <strong class="gl-text-gray-800 gl-mb-2">
                {{ $options.I18N.learnBasics.gettingStarted.title }}
              </strong>
            </div>
            <p class="gl-font-sm gl-h-13">
              {{ $options.I18N.learnBasics.gettingStarted.description }}
            </p>
          </div>

          <gl-button
            category="primary"
            variant="confirm"
            :href="gettingStartedTemplateUrl"
            data-testid="test-template-link"
            @click="trackEvent('template_clicked', $options.STARTER_TEMPLATE_NAME)"
          >
            {{ $options.I18N.learnBasics.gettingStarted.cta }}
          </gl-button>
        </gl-card>
      </div>
    </div>

    <h2 class="gl-font-lg gl-text-gray-900">{{ $options.I18N.templates.title }}</h2>
    <p class="gl-text-gray-800 gl-mb-6">{{ $options.I18N.templates.subtitle }}</p>

    <ci-templates />
  </div>
</template>
