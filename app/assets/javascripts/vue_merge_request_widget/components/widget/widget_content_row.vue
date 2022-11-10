<script>
import { GlSafeHtmlDirective, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { EXTENSION_ICONS } from '../../constants';
import { generateText } from '../extensions/utils';
import StatusIcon from './status_icon.vue';

export default {
  components: {
    StatusIcon,
    HelpPopover,
    GlLink,
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
      required: false,
      default: '',
      validator: (value) => value === '' || Object.keys(EXTENSION_ICONS).includes(value),
    },
    widgetName: {
      type: String,
      required: true,
    },
    header: {
      type: [String, Array],
      required: false,
      default: '',
    },
    /**
     * @typedef {Object} helpPopover
     * @property {Object} options
     * @property {String} options.title
     * @property {Object} content
     * @property {String} content.text
     * @property {String} content.learnMorePath
     */
    helpPopover: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    generatedHeader() {
      return generateText(Array.isArray(this.header) ? this.header[0] : this.header);
    },
    generatedSubheader() {
      return Array.isArray(this.header) && this.header[1] ? generateText(this.header[1]) : '';
    },
    shouldShowHeaderActions() {
      return Boolean(this.helpPopover);
    },
  },
  i18n: {
    learnMore: __('Learn more'),
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
        <div v-if="shouldShowHeaderActions" class="gl-ml-auto">
          <help-popover :options="helpPopover.options">
            <template v-if="helpPopover.content">
              <p
                v-if="helpPopover.content.text"
                v-safe-html="helpPopover.content.text"
                class="gl-mb-0"
              ></p>
              <gl-link
                v-if="helpPopover.content.learnMorePath"
                :href="helpPopover.content.learnMorePath"
                target="_blank"
                class="gl-font-sm"
                >{{ $options.i18n.learnMore }}</gl-link
              >
            </template>
          </help-popover>
        </div>
      </div>
      <div class="gl-display-flex gl-align-items-baseline gl-w-full">
        <slot name="body"></slot>
      </div>
    </div>
  </div>
</template>
