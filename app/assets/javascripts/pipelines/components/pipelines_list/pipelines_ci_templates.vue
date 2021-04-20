<script>
import { GlButton, GlCard, GlSprintf } from '@gitlab/ui';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import { HELLO_WORLD_TEMPLATE_KEY } from '../../constants';

export default {
  components: {
    GlButton,
    GlCard,
    GlSprintf,
  },
  HELLO_WORLD_TEMPLATE_KEY,
  i18n: {
    cta: s__('Pipelines|Use template'),
    testTemplates: {
      title: s__('Pipelines|Use a sample CI/CD template'),
      subtitle: s__(
        'Pipelines|Use a sample %{codeStart}.gitlab-ci.yml%{codeEnd} template file to explore how CI/CD works.',
      ),
      helloWorld: {
        title: s__('Pipelines|“Hello world” with GitLab CI/CD'),
        description: s__(
          'Pipelines|Get familiar with GitLab CI/CD syntax by starting with a simple pipeline that runs a “Hello world” script.',
        ),
      },
    },
    templates: {
      title: s__('Pipelines|Use a CI/CD template'),
      subtitle: s__(
        "Pipelines|Use a template based on your project's language or framework to get started with GitLab CI/CD.",
      ),
      description: s__('Pipelines|CI/CD template to test and deploy your %{name} project.'),
    },
  },
  inject: ['addCiYmlPath', 'suggestedCiTemplates'],
  data() {
    const templates = this.suggestedCiTemplates.map(({ name, logo }) => {
      return {
        name,
        logo,
        link: mergeUrlParams({ template: name }, this.addCiYmlPath),
        description: sprintf(this.$options.i18n.templates.description, { name }),
      };
    });

    return {
      templates,
      helloWorldTemplateUrl: mergeUrlParams(
        { template: HELLO_WORLD_TEMPLATE_KEY },
        this.addCiYmlPath,
      ),
    };
  },
  methods: {
    trackEvent(template) {
      const tracking = new ExperimentTracking('pipeline_empty_state_templates', {
        label: template,
      });
      tracking.event('template_clicked');
    },
  },
};
</script>
<template>
  <div>
    <h2 class="gl-font-size-h2 gl-text-gray-900">{{ $options.i18n.testTemplates.title }}</h2>
    <p class="gl-text-gray-800 gl-mb-6">
      <gl-sprintf :message="$options.i18n.testTemplates.subtitle">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>

    <div class="row gl-mb-8">
      <div class="col-lg-3">
        <gl-card>
          <div class="gl-flex-direction-row">
            <div class="gl-py-5"><gl-emoji class="gl-font-size-h2-xl" data-name="wave" /></div>
            <div class="gl-mb-3">
              <strong class="gl-text-gray-800 gl-mb-2">{{
                $options.i18n.testTemplates.helloWorld.title
              }}</strong>
            </div>
            <p class="gl-font-sm">{{ $options.i18n.testTemplates.helloWorld.description }}</p>
          </div>

          <gl-button
            category="primary"
            variant="confirm"
            :href="helloWorldTemplateUrl"
            data-testid="test-template-link"
            @click="trackEvent($options.HELLO_WORLD_TEMPLATE_KEY)"
          >
            {{ $options.i18n.cta }}
          </gl-button>
        </gl-card>
      </div>
    </div>

    <h2 class="gl-font-size-h2 gl-text-gray-900">{{ $options.i18n.templates.title }}</h2>
    <p class="gl-text-gray-800 gl-mb-6">{{ $options.i18n.templates.subtitle }}</p>

    <ul class="gl-list-style-none gl-pl-0">
      <li v-for="template in templates" :key="template.name">
        <div
          class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-pb-3 gl-pt-3"
        >
          <div class="gl-display-flex gl-flex-direction-row gl-align-items-center">
            <img
              width="64"
              height="64"
              :src="template.logo"
              class="gl-mr-6"
              data-testid="template-logo"
            />
            <div class="gl-flex-direction-row">
              <div class="gl-mb-3">
                <strong class="gl-text-gray-800" data-testid="template-name">{{
                  template.name
                }}</strong>
              </div>
              <p class="gl-mb-0 gl-font-sm" data-testid="template-description">
                {{ template.description }}
              </p>
            </div>
          </div>
          <gl-button
            category="primary"
            variant="confirm"
            :href="template.link"
            data-testid="template-link"
            @click="trackEvent(template.name)"
          >
            {{ $options.i18n.cta }}
          </gl-button>
        </div>
      </li>
    </ul>
  </div>
</template>
