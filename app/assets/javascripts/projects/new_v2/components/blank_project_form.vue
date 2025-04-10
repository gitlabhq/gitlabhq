<script>
import { GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SharedProjectCreationFields from './shared_project_creation_fields.vue';

export default {
  components: {
    GlButton,
    MultiStepFormTemplate,
    SharedProjectCreationFields,
  },
  props: {
    option: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    namespace: {
      type: Object,
      required: true,
    },
  },
  methods: {
    onSelectNamespace(newNamespace) {
      this.$emit('onSelectNamespace', newNamespace);
    },
  },
};
</script>

<template>
  <multi-step-form-template :title="option.title" :current-step="2" :steps-total="2">
    <template #form>
      <shared-project-creation-fields
        :namespace="namespace"
        @onSelectNamespace="onSelectNamespace"
      />
      <!-- Project Configuration and Experimental features will be added here in: https://gitlab.com/gitlab-org/gitlab/-/issues/514700 -->

      <!-- Two checkboxes from JiHu should be added here in: https://gitlab.com/gitlab-org/gitlab/-/issues/514700 -->
    </template>
    <template #next>
      <gl-button
        category="primary"
        variant="confirm"
        :disabled="true"
        data-testid="create-project-button"
        @click="$emit('create-project')"
      >
        {{ __('Create project') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button
        category="primary"
        data-testid="create-project-back-button"
        variant="default"
        @click="$emit('back')"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
