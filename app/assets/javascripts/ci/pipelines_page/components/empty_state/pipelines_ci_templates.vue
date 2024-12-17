<script>
import { s__ } from '~/locale';

import CiCards from './ci_cards.vue';
import CiTemplates from './ci_templates.vue';

export default {
  name: 'PipelinesCiTemplates',
  i18n: {
    title: s__('Pipelines|Get started with GitLab CI/CD'),
    learnBasics: {
      title: s__('Pipelines|Learn the basics of pipelines and .yml files'),
      subtitle: s__(
        'Pipelines|Use CI/CD pipelines to automatically build, test, and deploy your code.',
      ),
    },
    templates: {
      title: s__('Pipelines|Ready to set up CI/CD for your project?'),
      subtitle: s__(
        "Pipelines|Use a template based on your project's language or framework to get started with GitLab CI/CD.",
      ),
    },
  },
  components: {
    CiCards,
    CiTemplates,
  },
};
</script>

<template>
  <div>
    <h2 class="gl-text-size-h2">{{ $options.i18n.title }}</h2>

    <div class="gl-mb-8">
      <h3 class="gl-text-lg">{{ $options.i18n.learnBasics.title }}</h3>
      <p class="gl-mb-6 gl-text-default">{{ $options.i18n.learnBasics.subtitle }}</p>
      <ci-cards />
    </div>

    <div>
      <h3 class="gl-text-lg">{{ $options.i18n.templates.title }}</h3>
      <p class="gl-mb-6 gl-text-default">{{ $options.i18n.templates.subtitle }}</p>
      <ci-templates />
    </div>
  </div>
</template>
