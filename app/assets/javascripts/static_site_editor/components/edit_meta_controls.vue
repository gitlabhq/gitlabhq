<script>
import { GlForm, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';

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
  computed: {
    editableStorageKey() {
      return this.getId('local-storage', 'editable');
    },
    hasLocalStorage() {
      return AccessorUtilities.isLocalStorageAccessSafe();
    },
  },
  mounted() {
    this.initCachedEditable();
    this.preSelect();
  },
  methods: {
    getId(type, key) {
      return `sse-merge-request-meta-${type}-${key}`;
    },
    initCachedEditable() {
      if (this.hasLocalStorage) {
        const cachedEditable = JSON.parse(localStorage.getItem(this.editableStorageKey));
        if (cachedEditable) {
          this.editable = cachedEditable;
        }
      }
    },
    preSelect() {
      this.$nextTick(() => {
        this.$refs.title.$el.select();
      });
    },
    resetCachedEditable() {
      if (this.hasLocalStorage) {
        window.localStorage.removeItem(this.editableStorageKey);
      }
    },
    onUpdate() {
      const payload = { ...this.editable };
      this.$emit('updateSettings', payload);

      if (this.hasLocalStorage) {
        window.localStorage.setItem(this.editableStorageKey, JSON.stringify(payload));
      }
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
