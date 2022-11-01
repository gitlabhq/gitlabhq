<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import { EXTENSION_ICONS } from '../../constants';
import { generateText } from '../extensions/utils';
import StatusIcon from './status_icon.vue';

export default {
  components: {
    StatusIcon,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    level: {
      type: Number,
      required: true,
      validator: (value) => value === 2 || value === 3,
    },
    statusIconName: {
      type: String,
      default: '',
      required: false,
      validator: (value) => value === '' || Object.keys(EXTENSION_ICONS).includes(value),
    },
    widgetName: {
      type: String,
      required: true,
    },
    header: {
      type: [String, Array],
      default: '',
      required: false,
    },
  },
  computed: {
    generatedHeader() {
      return generateText(Array.isArray(this.header) ? this.header[0] : this.header);
    },
    generatedSubheader() {
      return Array.isArray(this.header) && this.header[1] ? generateText(this.header[1]) : '';
    },
  },
};
</script>
<template>
  <div
    class="gl-w-full gl-display-flex mr-widget-content-row gl-align-items-baseline"
    :class="{ 'gl-border-t gl-py-3 gl-pl-7': level === 2 }"
  >
    <status-icon v-if="statusIconName" :level="2" :name="widgetName" :icon-name="statusIconName" />
    <div class="gl-w-full">
      <div class="gl-display-flex">
        <slot name="header">
          <div v-if="header" class="gl-mb-2">
            <strong v-safe-html="generatedHeader" class="gl-display-block"></strong
            ><span
              v-if="generatedSubheader"
              v-safe-html="generatedSubheader"
              class="gl-display-block"
            ></span>
          </div>
        </slot>
        <div v-if="$scopedSlots['header-actions']" class="gl-ml-auto">
          <slot name="header-actions"></slot>
        </div>
      </div>
      <div class="gl-display-flex gl-align-items-baseline gl-w-full">
        <slot name="body"></slot>
      </div>
    </div>
  </div>
</template>
