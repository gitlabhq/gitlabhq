<script>
import { GlFormGroup, GlFormCheckbox, GlFormCheckboxGroup } from '@gitlab/ui';
import { uniqueId } from 'lodash';

const isValidItemDefinition = (value) => {
  // The Item definition should either be a simple string
  // or an object with at least a "title" property
  return typeof value === 'string' || Boolean(value.text);
};

export default {
  name: 'ChecklistWidget',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormCheckboxGroup,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: null,
    },
    items: {
      type: Array,
      required: false,
      validator: (v) => v.every(isValidItemDefinition),
      default: () => [],
    },
    validate: {
      type: Boolean,
      required: false,
      default: false,
    },
    id: {
      type: String,
      required: false,
      default: () => uniqueId('checklist_'),
    },
  },
  computed: {
    checklistItems() {
      return this.items.map((rawItem) => {
        const id = rawItem.id || uniqueId();
        return {
          id,
          text: rawItem.text || rawItem,
          help: rawItem.help || null,
        };
      });
    },
  },
  created() {
    if (this.items.length > 0) {
      this.$emit('update:valid', false);
    }
  },
  methods: {
    updateValidState(values) {
      this.$emit(
        'update:valid',
        this.checklistItems.every((item) => values.includes(item.id)),
      );
    },
  },
};
</script>

<template>
  <gl-form-group :label="title" :label-for="id">
    <gl-form-checkbox-group :id="id" :label="title" @input="updateValidState">
      <gl-form-checkbox
        v-for="item in checklistItems"
        :id="item.id"
        :key="item.id"
        :value="item.id"
      >
        {{ item.text }}
        <template v-if="item.help" #help>
          {{ item.help }}
        </template>
      </gl-form-checkbox>
    </gl-form-checkbox-group>
  </gl-form-group>
</template>
