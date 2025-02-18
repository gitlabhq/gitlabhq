<script>
import { GlTable, GlFormInput } from '@gitlab/ui';
import { memoize } from 'lodash';
import { __ } from '~/locale';
import { sanitize } from '~/lib/dompurify';
import SafeHtml from '~/vue_shared/directives/safe_html';

const domParser = new DOMParser();

export default {
  directives: {
    SafeHtml,
  },
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
    isHtmlSafe: {
      type: Boolean,
      required: false,
      default: false,
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
          sortByFormatted: field.sortable && this.isHtmlSafe ? this.getSortableFieldValue : false,
          class: field.class || [],
          markdown: field.markdown || false,
        };
      });
    },
  },
  created() {
    this.getSortableFieldValue = memoize((value) => {
      const document = domParser.parseFromString(sanitize(value), 'text/html');

      return document.documentElement.innerText.trim();
    });
  },
  methods: {
    cellSlot(field) {
      return `cell(${field.key})`;
    },
  },
};
</script>
<template>
  <div class="gl-inline-block gl-max-w-full">
    <gl-form-input
      v-if="hasFilter"
      v-model="filterInput"
      :placeholder="__('Type to search')"
      class="!gl-mb-2"
    />
    <gl-table
      :fields="cleanedFields"
      :items="items"
      :filter="filterInput"
      show-empty
      class="!gl-mt-0"
    >
      <template v-if="isHtmlSafe" #cell()="data">
        <div v-safe-html="data.value"></div>
      </template>
      <template v-else #cell()="data">{{ data.value }}</template>
      <template v-if="caption" #table-caption>
        <small v-if="isHtmlSafe" v-safe-html="caption"></small>
        <small v-else>{{ caption }}</small>
      </template>
    </gl-table>
  </div>
</template>
