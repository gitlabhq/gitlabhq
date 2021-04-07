<script>
import { GlButton } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import { SUGGESTED_CI_TEMPLATES } from '../../constants';

export default {
  components: {
    GlButton,
  },
  i18n: {
    title: s__('Pipelines|Try a sample CI/CD file'),
    subtitle: s__(
      'Pipelines|Use a sample file to implement GitLab CI/CD based on your project’s language/framework.',
    ),
    cta: s__('Pipelines|Use template'),
    description: s__(
      'Pipelines|Continuous deployment template to test and deploy your %{name} project.',
    ),
    errorMessage: s__('Pipelines|An error occurred. Please try again.'),
  },
  inject: ['addCiYmlPath'],
  data() {
    const templates = Object.keys(SUGGESTED_CI_TEMPLATES).map((key) => {
      return {
        name: key,
        logoPath: SUGGESTED_CI_TEMPLATES[key].logoPath,
        link: mergeUrlParams({ template: key }, this.addCiYmlPath),
        description: sprintf(this.$options.i18n.description, { name: key }),
      };
    });

    return {
      templates,
    };
  },
};
</script>
<template>
  <div>
    <h2>{{ $options.i18n.title }}</h2>
    <p>{{ $options.i18n.subtitle }}</p>

    <ul class="gl-list-style-none gl-pl-0">
      <li v-for="template in templates" :key="template.key">
        <div
          class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-pb-5 gl-pt-5"
        >
          <div class="gl-display-flex gl-flex-direction-row gl-align-items-center">
            <img
              width="64"
              height="64"
              :src="template.logoPath"
              class="gl-mr-6"
              data-testid="template-logo"
            />
            <div class="gl-flex-direction-row">
              <strong class="gl-text-gray-800">{{ template.name }}</strong>
              <p class="gl-mb-0" data-testid="template-description">{{ template.description }}</p>
            </div>
          </div>
          <gl-button
            category="primary"
            variant="confirm"
            :href="template.link"
            data-testid="template-link"
            >{{ $options.i18n.cta }}</gl-button
          >
        </div>
      </li>
    </ul>
  </div>
</template>
