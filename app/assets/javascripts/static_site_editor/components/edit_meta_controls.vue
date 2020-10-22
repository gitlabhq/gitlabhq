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
  mounted() {
    this.preSelect();
  },
  methods: {
    getId(type, key) {
      return `sse-merge-request-meta-${type}-${key}`;
    },
    preSelect() {
      this.$nextTick(() => {
        this.$refs.title.$el.select();
      });
    },
    onUpdate(field, value) {
      const payload = {
        title: this.title,
        description: this.description,
        [field]: value,
      };
      this.$emit('updateSettings', payload);
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
        ref="title"
        :value="title"
        type="text"
        @input="onUpdate('title', $event)"
      />
    </gl-form-group>

    <gl-form-group
      key="description"
      :label="__('Goal of the changes and what reviewers should be aware of')"
      :label-for="getId('control', 'description')"
    >
      <gl-form-textarea
        :id="getId('control', 'description')"
        :value="description"
        @input="onUpdate('description', $event)"
      />
    </gl-form-group>
  </gl-form>
</template>
