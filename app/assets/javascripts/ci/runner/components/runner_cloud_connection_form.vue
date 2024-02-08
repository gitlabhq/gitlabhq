<script>
import {
  GlAccordion,
  GlAccordionItem,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlIcon,
  GlLink,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import CodeBlock from '~/vue_shared/components/code_block.vue';

export default {
  name: 'RunnerCloudForm',
  i18n: {
    title: s__('Runners|Google Cloud'),
    description: s__(
      'Runners|To improve security, use a dedicated project for CI/CD, separate from resources and identity management projects.',
    ),
    docsLinkText: s__('Runners|Where’s my project ID in Google Cloud?'),
    projectIdLabel: s__('Runners|Google Cloud project ID'),
    helpText: s__('Runners|Project for the new runner.'),
    configurationLabel: s__('Runners|Configuration'),
    configurationHelpText: s__(
      "Runners|If you haven't already, configure your Google Cloud project to connect to this GitLab project and use the runner.",
    ),
    accordionTitle: s__('Runners|Configuration instructions'),
    continueBtnText: s__('Runners|Continue to runner details'),
  },
  components: {
    CodeBlock,
    GlAccordion,
    GlAccordionItem,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
  },
  data() {
    return {
      projectId: '',
      /* eslint-disable @gitlab/require-i18n-strings */
      configurationScript: `hello world.`,
      /* eslint-enable @gitlab/require-i18n-strings */
    };
  },
};
</script>
<template>
  <div>
    <h2 class="gl-font-size-h2 gl-mb-5">{{ $options.i18n.title }}</h2>

    <gl-form>
      <gl-form-group label-for="project-id">
        <template #label>
          <div class="gl-mb-3">{{ $options.i18n.projectIdLabel }}</div>
          <span class="gl-font-weight-normal">{{ $options.i18n.helpText }}</span>
        </template>
        <template #description>
          <span class="gl-display-block gl-mb-2">{{ $options.i18n.description }}</span>

          <gl-link
            href="https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects"
            target="_blank"
          >
            {{ $options.i18n.docsLinkText }}
            <gl-icon name="external-link" />
          </gl-link>
        </template>
        <gl-form-input
          id="project-id"
          v-model="projectId"
          type="text"
          data-testid="project-id-input"
        />
      </gl-form-group>
    </gl-form>

    <label>{{ $options.i18n.configurationLabel }}</label>
    <p>{{ $options.i18n.configurationHelpText }}</p>

    <gl-accordion :header-level="3">
      <gl-accordion-item :title="$options.i18n.accordionTitle" :header-level="3" visible>
        <!-- TODO add configuration setup details https://gitlab.com/gitlab-org/gitlab/-/issues/439486 -->
        <code-block
          :code="configurationScript"
          class="gl-border-1 gl-border-solid gl-border-gray-200 gl-p-3!"
        />
      </gl-accordion-item>
    </gl-accordion>

    <gl-button
      class="gl-mt-5"
      variant="confirm"
      data-testid="continue-btn"
      @click="$emit('continue', projectId)"
    >
      {{ $options.i18n.continueBtnText }}
    </gl-button>
  </div>
</template>
