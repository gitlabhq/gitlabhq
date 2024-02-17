<script>
import { GlBadge, GlLink, GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { generateText } from './utils';
import ContentRow from './widget_content_row.vue';
import Actions from './action_buttons.vue';

export default {
  name: 'DynamicContent',
  components: {
    GlBadge,
    GlLink,
    Actions,
    ContentRow,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    widgetName: {
      type: String,
      required: true,
    },
    level: {
      type: Number,
      required: false,
      default: 2,
    },
    rowIndex: {
      type: Number,
      required: false,
      default: -1,
    },
  },
  computed: {
    statusIcon() {
      return this.data.icon?.name || undefined;
    },
    generatedText() {
      return generateText(this.data.text);
    },
    generatedSubtext() {
      return generateText(this.data.subtext);
    },
    generatedSupportingText() {
      return generateText(this.data.supportingText);
    },
    shouldShowThirdLevel() {
      return this.data.children?.length > 0 && this.level === 2;
    },
    hasActionButtons() {
      return this.data.actions?.length > 0;
    },
  },
  methods: {
    onClickedAction(action) {
      this.$emit('clickedAction', action);
    },
  },
};
</script>

<template>
  <content-row
    :level="level"
    :status-icon-name="statusIcon"
    :widget-name="widgetName"
    :header="data.header"
    :help-popover="data.helpPopover"
    :class="{
      'gl-border-top-0': rowIndex === 0,
      'gl-align-items-start': data.supportingText,
      'gl-align-items-baseline': !data.supportingText,
    }"
  >
    <template #body>
      <div class="gl-w-full gl-display-flex gl-flex-direction-column">
        <div class="gl-display-flex gl-flex-grow-1">
          <div class="gl-display-flex gl-flex-grow-1 gl-align-items-baseline">
            <div>
              <p
                v-gl-tooltip="{ title: data.tooltipText, boundary: 'viewport' }"
                v-safe-html="generatedText"
                class="gl-mb-0 gl-mr-1"
              ></p>
              <gl-link v-if="data.link" :href="data.link.href">{{ data.link.text }}</gl-link>
              <p
                v-if="data.supportingText"
                v-safe-html="generatedSupportingText"
                class="gl-mb-0"
              ></p>
            </div>
            <gl-badge v-if="data.badge" :variant="data.badge.variant || 'info'">
              {{ data.badge.text }}
            </gl-badge>
          </div>
          <actions
            v-if="hasActionButtons"
            :tertiary-buttons="data.actions"
            class="gl-ml-auto gl-pl-3"
            @clickedAction="onClickedAction"
          />
          <p v-if="data.subtext" v-safe-html="generatedSubtext" class="gl-m-0 gl-font-sm"></p>
        </div>
        <ul v-if="shouldShowThirdLevel" class="gl-m-0 gl-p-0 gl-list-style-none">
          <li v-for="(childData, index) in data.children" :key="childData.id || index">
            <dynamic-content
              :data="childData"
              :widget-name="widgetName"
              :level="3"
              @clickedAction="onClickedAction"
            />
          </li>
        </ul>
      </div>
    </template>
  </content-row>
</template>
