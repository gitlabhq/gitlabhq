<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import ActionButtons from '~/vue_merge_request_widget/components/widget/action_buttons.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { generateText } from '~/vue_merge_request_widget/components/widget/utils';

export const SECTION_ITEM_LEVEL = 2;

export default {
  name: 'ReportSection',
  components: {
    GlBadge,
    GlLink,
    HelpPopover,
    StatusIcon,
    ActionButtons,
  },
  directives: {
    SafeHtml,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    summary: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    statusIconName: {
      type: String,
      required: false,
      default: 'neutral',
      validator: (value) => Object.keys(EXTENSION_ICONS).includes(value),
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
    helpPopover: {
      type: Object,
      required: false,
      default: null,
    },
    loadingText: {
      type: String,
      required: false,
      default: '',
    },
    sections: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    hasActionButtons() {
      return this.actionButtons.length > 0;
    },
    summaryTitle() {
      return this.summary.title ? generateText(this.summary.title) : '';
    },
    hasSections() {
      return this.sections.length > 0;
    },
  },
  methods: {
    generateText,
  },
  SECTION_ITEM_LEVEL,
  i18n: {
    learnMore: __('Learn more'),
  },
};
</script>

<template>
  <section class="media-section" data-testid="report">
    <div class="gl-flex gl-px-5 gl-py-4">
      <status-icon :level="1" :is-loading="isLoading" :icon-name="statusIconName" name="Report" />
      <div v-if="isLoading" class="media-body gl-flex !gl-flex-row gl-self-center">
        <div class="gl-grow" data-testid="loading-text">{{ loadingText }}</div>
      </div>
      <template v-else>
        <div class="media-body gl-flex !gl-flex-row gl-self-center">
          <div class="gl-grow">
            <span v-if="summaryTitle" v-safe-html="summaryTitle" data-testid="summary"></span>
          </div>
          <div class="gl-flex">
            <help-popover
              v-if="helpPopover"
              icon="information-o"
              :options="helpPopover.options"
              :class="{ 'gl-mr-3': hasActionButtons }"
            >
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
                  class="gl-text-sm"
                  >{{ $options.i18n.learnMore }}</gl-link
                >
              </template>
            </help-popover>
            <action-buttons v-if="hasActionButtons" :tertiary-buttons="actionButtons" />
          </div>
        </div>
      </template>
    </div>
    <div v-if="hasSections" data-testid="sections">
      <div
        v-for="(section, sectionIndex) in sections"
        :key="section.header || sectionIndex"
        class="gl-border-t gl-flex gl-border-t-section gl-py-3 gl-pl-7"
        data-testid="section"
      >
        <div class="gl-w-full gl-min-w-0">
          <div v-if="section.header" class="gl-mb-2">
            <strong class="gl-block" data-testid="section-header">{{ section.header }}</strong>
            <span
              v-if="section.text"
              class="gl-block gl-text-secondary"
              data-testid="section-text"
              >{{ section.text }}</span
            >
          </div>
          <div
            v-for="(item, index) in section.children"
            :key="index"
            class="gl-border-t gl-flex gl-items-baseline gl-border-t-section gl-py-3"
            :class="{ 'gl-border-t-0': index === 0 }"
            data-testid="section-item"
          >
            <status-icon
              v-if="item.icon"
              :level="$options.SECTION_ITEM_LEVEL"
              :icon-name="item.icon.name"
              name="ReportItem"
            />
            <div class="gl-flex gl-grow gl-items-baseline">
              <div>
                <p
                  v-if="item.text"
                  v-safe-html="generateText(item.text)"
                  class="gl-mb-0 gl-mr-1"
                  data-testid="item-text"
                ></p>
                <gl-link v-if="item.link" :href="item.link.href">{{ item.link.text }}</gl-link>
                <p
                  v-if="item.supportingText"
                  v-safe-html="item.supportingText"
                  class="gl-mb-0 gl-text-secondary"
                  data-testid="item-supporting-text"
                ></p>
              </div>
              <gl-badge
                v-if="item.badge"
                :variant="item.badge.variant || 'info'"
                data-testid="item-badge"
              >
                {{ item.badge.text }}
              </gl-badge>
            </div>
            <action-buttons
              v-if="item.actions && item.actions.length"
              :tertiary-buttons="item.actions"
              class="gl-ml-auto gl-pl-3"
            />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
