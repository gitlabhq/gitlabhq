<script>
import { GlTable, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlTable,
    GlFormInput,
  },
  props: {
    fields: {
      type: Array,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    hasFilter: {
      type: Boolean,
      required: false,
      default: false,
    },
    caption: {
      type: String,
      required: false,
      default: __('Generated with JSON data'),
    },
  },
  data() {
    return {
      filterInput: '',
    };
  },
  computed: {
    cleanedFields() {
      return this.fields.map((field) => {
        if (typeof field === 'string') {
          return field;
        }
        return {
          key: field.key,
          label: field.label,
          sortable: field.sortable || false,
          class: field.class || [],
        };
      });
    },
  },
};
</script>
<template>
  <div class="gl-display-inline-block gl-max-w-full">
    <gl-form-input
      v-if="hasFilter"
      v-model="filterInput"
      :placeholder="__('Type to search')"
      class="gl-mb-2!"
    />
    <gl-table
      :fields="cleanedFields"
      :items="items"
      :filter="filterInput"
      show-empty
      class="gl-mt-0!"
    >
      <template v-if="caption" #table-caption>
        <small>{{ caption }}</small>
      </template>
    </gl-table>
  </div>
</template>
