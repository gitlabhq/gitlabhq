<script>
import { GlAvatar, GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import Tracking from '~/tracking';

export default {
  components: {
    GlAvatar,
    GlButton,
  },
  mixins: [Tracking.mixin()],
  inject: ['pipelineEditorPath', 'suggestedCiTemplates'],
  data() {
    const templates = this.suggestedCiTemplates.map(({ name, logo }) => {
      return {
        name,
        logo,
        link: mergeUrlParams({ template: name }, this.pipelineEditorPath),
        description: sprintf(this.$options.i18n.description, { name }),
      };
    });

    return {
      templates,
    };
  },
  methods: {
    trackEvent(template) {
      this.track('template_clicked', {
        label: template,
      });
    },
  },
  i18n: {
    description: s__('Pipelines|CI/CD template to test and deploy your %{name} project.'),
    cta: s__('Pipelines|Use template'),
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>
<template>
  <ul class="gl-list-style-none gl-pl-0">
    <li v-for="template in templates" :key="template.name">
      <div
        class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-pb-3 gl-pt-3"
      >
        <div class="gl-display-flex gl-flex-direction-row gl-align-items-center">
          <gl-avatar
            :src="template.logo"
            :size="48"
            class="gl-mr-5 gl-bg-white dark-mode-override"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            :alt="template.name"
            data-testid="template-logo"
          />
          <div class="gl-flex-direction-row">
            <div class="gl-mb-3">
              <strong class="gl-text-gray-800" data-testid="template-name">
                {{ template.name }}
              </strong>
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
</template>
