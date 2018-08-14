<script>
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
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
  },
};
</script>

<template>
  <div
    :class="{
      'has-labels':!isEmpty,
    }"
    class="hide-collapsed value issuable-show-labels js-value"
  >
    <span
      v-if="isEmpty"
      class="text-secondary"
    >
      <slot>{{ __('None') }}</slot>
    </span>
    <a
      v-for="label in labels"
      v-else
      :key="label.id"
      :href="labelFilterUrl(label)"
    >
      <span
        v-tooltip
        :style="labelStyle(label)"
        :title="label.description"
        class="badge color-label"
        data-placement="bottom"
        data-container="body"
      >
        {{ label.title }}
      </span>
    </a>
  </div>
</template>
