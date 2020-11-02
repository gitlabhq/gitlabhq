<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
} from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
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
    templates: {
      type: Array,
      required: false,
      default: null,
    },
    currentTemplate: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    dropdownLabel() {
      return this.currentTemplate ? this.currentTemplate.name : __('None');
    },
    hasTemplates() {
      return this.templates?.length > 0;
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
    onChangeTemplate(template) {
      this.$emit('changeTemplate', template || null);
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
      v-if="hasTemplates"
      key="template"
      :label="__('Description template')"
      :label-for="getId('control', 'template')"
    >
      <gl-dropdown :text="dropdownLabel">
        <gl-dropdown-item key="none" @click="onChangeTemplate(null)">
          {{ __('None') }}
        </gl-dropdown-item>

        <gl-dropdown-divider />

        <gl-dropdown-item
          v-for="template in templates"
          :key="template.key"
          @click="onChangeTemplate(template)"
        >
          {{ template.name }}
        </gl-dropdown-item>
      </gl-dropdown>
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
