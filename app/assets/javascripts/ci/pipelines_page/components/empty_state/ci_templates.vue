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
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    filterTemplates: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    const templates = this.suggestedCiTemplates
      .filter(
        (template) => !this.filterTemplates.length || this.filterTemplates.includes(template.name),
      )
      .map(({ name, logo, title }) => {
        return {
          name: title || name,
          description: sprintf(this.$options.i18n.description, { name: title || name }),
          isPng: logo.endsWith('png'),
          logo,
          link: mergeUrlParams({ template: name }, this.pipelineEditorPath),
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
    logoStyle(template) {
      return template.isPng ? { objectFit: 'contain' } : '';
    },
  },
  i18n: {
    description: s__(
      'Pipelines|Continuous integration and deployment template to test and deploy your %{name} project.',
    ),
    cta: s__('Pipelines|Use template'),
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>
<template>
  <ul class="gl-list-none gl-pl-0">
    <li v-for="template in templates" :key="template.name">
      <div
        class="gl-flex gl-items-center gl-justify-between gl-border-b-1 gl-border-b-default gl-pb-3 gl-pt-3 gl-border-b-solid"
      >
        <div class="gl-flex gl-flex-row gl-items-center">
          <gl-avatar
            :alt="template.name"
            class="dark-mode-override gl-mr-5 gl-bg-white"
            :class="{ 'gl-p-2': template.isPng }"
            :style="logoStyle(template)"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            :size="48"
            :src="template.logo"
            data-testid="template-logo"
          />
          <div class="gl-flex-row">
            <div class="gl-mb-3">
              <strong class="gl-text-default" data-testid="template-name">
                {{ template.name }}
              </strong>
            </div>
            <p class="gl-mb-0 gl-text-sm" data-testid="template-description">
              {{ template.description }}
            </p>
          </div>
        </div>
        <gl-button
          :disabled="disabled"
          category="primary"
          variant="default"
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
