<script>
import { GlForm, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      editable: {
        title: this.title,
        description: this.description,
      },
    };
  },
  methods: {
    getId(type, key) {
      return `sse-merge-request-meta-${type}-${key}`;
    },
    onUpdate() {
      this.$emit('updateSettings', { ...this.editable });
    },
  },
};
</script>

<template>
  <gl-form>
    <gl-form-group
      key="title"
      :label="__('Brief title about the change')"
      :label-for="getId('control', 'title')"
    >
      <gl-form-input
        :id="getId('control', 'title')"
        v-model.lazy="editable.title"
        type="text"
        @input="onUpdate"
      />
    </gl-form-group>

    <gl-form-group
      key="description"
      :label="__('Goal of the changes and what reviewers should be aware of')"
      :label-for="getId('control', 'description')"
    >
      <gl-form-textarea
        :id="getId('control', 'description')"
        v-model.lazy="editable.description"
        @input="onUpdate"
      />
    </gl-form-group>
  </gl-form>
</template>
