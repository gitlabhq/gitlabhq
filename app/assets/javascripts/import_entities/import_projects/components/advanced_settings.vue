<script>
import {
  GlAccordion,
  GlAccordionItem,
  GlAlert,
  GlSprintf,
  GlLink,
  GlForm,
  GlFormCheckbox,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlSprintf,
    GlLink,
    GlForm,
    GlFormCheckbox,
  },
  props: {
    stages: {
      required: true,
      type: Array,
    },
    value: {
      required: true,
      type: Object,
    },
    isInitiallyExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  docsLink: helpPagePath('user/project/import/github', {
    anchor: 'use-a-github-personal-access-token',
  }),
};
</script>
<template>
  <gl-accordion :header-level="3">
    <gl-accordion-item
      :title="s__('ImportProjects|Advanced import settings')"
      :visible="isInitiallyExpanded"
    >
      <gl-alert variant="warning" class="gl-mb-5" :dismissible="false"
        >{{
          s__('ImportProjects|The more information you select, the longer it will take to import.')
        }}
        <p class="mb-0">
          <gl-sprintf
            :message="
              s__(
                'ImportProjects|To import collaborators, or if your project has Git LFS files, you must use a classic personal access token with %{codeStart}read:org%{codeEnd} scope. %{linkStart}Learn more%{linkEnd}.',
              )
            "
          >
            <template #code="{ content }">
              <code class="gl-ml-2">{{ content }}</code>
            </template>
            <template #link="{ content }">
              <gl-link :href="$options.docsLink" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </gl-alert>
      <gl-form>
        <gl-form-checkbox
          v-for="{ name, label, details } in stages"
          :key="name"
          :checked="value[name]"
          :data-qa-option-name="name"
          data-testid="advanced-settings-checkbox"
          @change="$emit('input', { ...value, [name]: $event })"
        >
          {{ label }}
          <template v-if="details" #help>{{ details }} </template>
        </gl-form-checkbox>
      </gl-form>
    </gl-accordion-item>
  </gl-accordion>
</template>
