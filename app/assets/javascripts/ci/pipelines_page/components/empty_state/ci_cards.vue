<script>
import { GlButton, GlCard } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import {
  CATALOG_TRACKING_LABEL,
  GITLAB_UNIVERSITY_TRACKING_LABEL,
  MIGRATE_FROM_JENKINS_TRACKING_LABEL,
} from '~/ci/pipelines_page/constants';
import { STARTER_TEMPLATE_NAME } from '~/ci/pipeline_editor/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

const cards = {
  jenkins_migration_card: {
    id: 'jenkins_migration',
    buttonLink: helpPagePath('ci/migration/plan_a_migration'),
    buttonText: s__('Pipelines|Start with a migration plan'),
    description: s__(
      'Pipelines|Take advantage of simple, scalable pipelines and CI/CD-enabled features. You can view integration results, security scans, tests, code coverage and more directly in merge requests!',
    ),
    emoji: 'rocket',
    isVisible: false,
    styles: 'gl-bg-blue-50',
    title: s__('Pipelines|Migrate to GitLab CI/CD from Jenkins'),
    trackingLabel: MIGRATE_FROM_JENKINS_TRACKING_LABEL,
  },
  getting_started_card: {
    id: 'getting_started',
    buttonLink: '',
    buttonText: s__('Pipelines|Try test template'),
    description: s__(
      'Pipelines|Get familiar with GitLab CI syntax by setting up a simple pipeline running a "Hello world" script to see how it runs, explore how CI/CD works.',
    ),
    emoji: 'wave',
    isVisible: true,
    title: s__('Pipelines|"Hello world" with GitLab CI'),
    trackingLabel: STARTER_TEMPLATE_NAME,
  },
  gitlab_university_card: {
    id: 'gitlab_university',
    buttonLink: 'https://university.gitlab.com/pages/ci-cd-content',
    buttonText: s__('Pipelines|Access GitLab University'),
    description: s__(
      'Pipelines|Learn how to set up and use GitLab CI/CD with guided tutorials, videos, and best practices.',
    ),
    emoji: 'mortar_board',
    isVisible: true,
    title: s__('Pipelines|Learn CI/CD with GitLab University'),
    trackingLabel: GITLAB_UNIVERSITY_TRACKING_LABEL,
  },
  ci_cd_catalog_card: {
    id: 'ci_cd_catalog',
    buttonLink: '/explore/catalog',
    buttonText: s__('Pipelines|Explore CI/CD Catalog'),
    description: s__(
      'Pipelines|Explore CI components in the CI/CD Catalog to see if they suit your requirements.',
    ),
    emoji: 'bulb',
    isVisible: true,
    title: s__('Pipelines|Easy configuration with CI/CD Catalog'),
    trackingLabel: CATALOG_TRACKING_LABEL,
  },
};

export default {
  name: 'CiCards',
  components: {
    GlButton,
    GlCard,
  },
  mixins: [Tracking.mixin()],
  inject: ['pipelineEditorPath', 'showJenkinsCiPrompt'],
  computed: {
    cards() {
      return [
        {
          ...cards.jenkins_migration_card,
          isVisible: this.showJenkinsCiPrompt,
        },
        {
          ...cards.getting_started_card,
          buttonLink: this.gettingStartedTemplateUrl,
        },
        cards.gitlab_university_card,
        cards.ci_cd_catalog_card,
      ];
    },
    gettingStartedTemplateUrl() {
      return mergeUrlParams({ template: STARTER_TEMPLATE_NAME }, this.pipelineEditorPath);
    },
  },
  mounted() {
    if (this.showJenkinsCiPrompt) {
      this.trackEvent('render', MIGRATE_FROM_JENKINS_TRACKING_LABEL);
    }
  },
  methods: {
    trackEvent(label) {
      this.track('template_clicked', { label });
    },
  },
};
</script>
<template>
  <div class="gl-grid gl-gap-5 md:gl-grid-cols-2 lg:gl-grid-cols-4">
    <template v-for="card in cards">
      <gl-card
        v-if="card.isVisible"
        :key="card.id"
        :body-class="['gl-h-full']"
        :class="card.styles"
      >
        <div class="gl-flex !gl-h-full gl-flex-col gl-justify-between gl-gap-4">
          <div>
            <gl-emoji
              class="gl-pb-5 gl-text-size-h2-xl"
              :data-name="card.emoji"
              data-testid="ci-card-emoji"
            />
            <p class="gl-mb-3">
              <strong class="gl-mb-2 gl-text-default" data-testid="ci-card-title">{{
                card.title
              }}</strong>
            </p>
            <p class="gl-flex-grow gl-text-sm" data-testid="ci-card-description">
              {{ card.description }}
            </p>
          </div>

          <gl-button
            category="primary"
            variant="confirm"
            :href="card.buttonLink"
            target="_blank"
            @click="trackEvent(card.trackingLabel)"
          >
            {{ card.buttonText }}
          </gl-button>
        </div>
      </gl-card>
    </template>
  </div>
</template>
