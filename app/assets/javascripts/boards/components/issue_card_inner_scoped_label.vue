<script>
import { GlLink, GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlTooltip,
    GlLink,
  },
  props: {
    label: {
      type: Object,
      required: true,
    },
    labelStyle: {
      type: Object,
      required: true,
    },
    scopedLabelsDocumentationLink: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span
    class="d-inline-block position-relative scoped-label-wrapper append-right-4 prepend-top-4 board-label"
  >
    <a @click="$emit('scoped-label-click', label)">
      <span :ref="'labelTitleRef'" :style="labelStyle" class="badge label color-label">
        {{ label.title }}
      </span>
      <gl-tooltip :target="() => $refs.labelTitleRef" placement="top" boundary="viewport">
        <span class="font-weight-bold scoped-label-tooltip-title">{{ __('Scoped label') }}</span
        ><br />
        {{ label.description }}
      </gl-tooltip>
    </a>

    <gl-link :href="scopedLabelsDocumentationLink" target="_blank" class="label scoped-label"
      ><i class="fa fa-question-circle" :style="labelStyle"></i
    ></gl-link>
  </span>
</template>
