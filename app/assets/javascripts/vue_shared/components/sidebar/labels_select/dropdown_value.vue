<script>
import DropdownValueScopedLabel from './dropdown_value_scoped_label.vue';
import DropdownValueRegularLabel from './dropdown_value_regular_label.vue';

export default {
  components: {
    DropdownValueScopedLabel,
    DropdownValueRegularLabel,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
    labelFilterBasePath: {
      type: String,
      required: true,
    },
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    scopedLabelsDocumentationLink: {
      type: String,
      required: false,
      default: '#',
    },
  },
  computed: {
    isEmpty() {
      return this.labels.length === 0;
    },
  },
  methods: {
    labelFilterUrl(label) {
      return `${this.labelFilterBasePath}?label_name[]=${encodeURIComponent(label.title)}`;
    },
    labelStyle(label) {
      return {
        color: label.textColor,
        backgroundColor: label.color,
      };
    },
    scopedLabelsDescription({ description = '' }) {
      return `<span class="font-weight-bold scoped-label-tooltip-title">Scoped label</span><br />${description}`;
    },
    showScopedLabels({ title = '' }) {
      return this.enableScopedLabels && title.indexOf('::') !== -1;
    },
  },
};
</script>

<template>
  <div
    :class="{
      'has-labels': !isEmpty,
    }"
    class="hide-collapsed value issuable-show-labels js-value"
  >
    <span v-if="isEmpty" class="text-secondary">
      <slot>{{ __('None') }}</slot>
    </span>

    <template v-for="label in labels" v-else>
      <dropdown-value-scoped-label
        v-if="showScopedLabels(label)"
        :key="label.id"
        :label="label"
        :label-filter-url="labelFilterUrl(label)"
        :label-style="labelStyle(label)"
        :scoped-labels-documentation-link="scopedLabelsDocumentationLink"
      />

      <dropdown-value-regular-label
        v-else
        :key="label.id"
        :label="label"
        :label-filter-url="labelFilterUrl(label)"
        :label-style="labelStyle(label)"
      />
    </template>
  </div>
</template>
