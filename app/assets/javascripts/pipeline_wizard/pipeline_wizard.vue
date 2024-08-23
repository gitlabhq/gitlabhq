<script>
import { parseDocument } from 'yaml';
import { DEFAULT_CI_CONFIG_PATH } from '~/lib/utils/constants';
import WizardWrapper from './components/wrapper.vue';

export default {
  name: 'PipelineWizard',
  components: {
    WizardWrapper,
  },
  props: {
    template: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    defaultFilename: {
      type: String,
      required: false,
      default: DEFAULT_CI_CONFIG_PATH,
    },
  },
  computed: {
    parsedTemplate() {
      return this.template ? parseDocument(this.template) : null;
    },
    title() {
      return this.parsedTemplate?.get('title');
    },
    description() {
      return this.parsedTemplate?.get('description');
    },
    filename() {
      return this.parsedTemplate?.get('filename') || this.defaultFilename;
    },
    steps() {
      return this.parsedTemplate?.get('steps');
    },
    templateId() {
      return this.parsedTemplate?.get('id');
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-my-8">
      <h1 class="gl-mb-4" data-testid="title">{{ title }}</h1>
      <p class="gl-max-w-80 gl-text-lg gl-text-subtle" data-testid="description">
        {{ description }}
      </p>
    </div>
    <wizard-wrapper
      v-if="steps"
      :default-branch="defaultBranch"
      :filename="filename"
      :project-path="projectPath"
      :steps="steps"
      :template-id="templateId"
      @done="$emit('done')"
    />
  </div>
</template>
