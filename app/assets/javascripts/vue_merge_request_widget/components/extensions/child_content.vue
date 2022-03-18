<script>
import { GlBadge, GlLink, GlSafeHtmlDirective } from '@gitlab/ui';
import StatusIcon from './status_icon.vue';
import Actions from './actions.vue';
import { generateText } from './utils';

export default {
  name: 'ChildContent',
  components: {
    GlBadge,
    GlLink,
    StatusIcon,
    Actions,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    widgetLabel: {
      type: String,
      required: true,
    },
    level: {
      type: Number,
      required: true,
    },
  },
  methods: {
    isArray(arr) {
      return Array.isArray(arr);
    },
    generateText,
  },
};
</script>

<template>
  <div :class="{ 'gl-pl-6': level === 3 }" class="gl-w-full">
    <div v-if="data.header" class="gl-mb-2">
      <template v-if="isArray(data.header)">
        <component
          :is="headerI === 0 ? 'strong' : 'span'"
          v-for="(header, headerI) in data.header"
          :key="headerI"
          v-safe-html="generateText(header)"
          class="gl-display-block"
        />
      </template>
      <strong v-else v-safe-html="generateText(data.header)"></strong>
    </div>
    <div class="gl-display-flex">
      <status-icon v-if="data.icon" :icon-name="data.icon.name" :size="12" class="gl-pl-0" />
      <div class="gl-w-full">
        <div class="gl-flex-wrap gl-display-flex gl-w-full">
          <div class="gl-mr-4 gl-display-flex gl-align-items-center">
            <p v-safe-html="generateText(data.text)" class="gl-m-0"></p>
          </div>
          <div v-if="data.link">
            <gl-link :href="data.link.href">{{ data.link.text }}</gl-link>
          </div>
          <div v-if="data.supportingText">
            <p v-safe-html="generateText(data.supportingText)" class="gl-m-0"></p>
          </div>
          <gl-badge v-if="data.badge" :variant="data.badge.variant || 'info'">
            {{ data.badge.text }}
          </gl-badge>
          <actions :widget="widgetLabel" :tertiary-buttons="data.actions" class="gl-ml-auto" />
        </div>
        <p
          v-if="data.subtext"
          v-safe-html="generateText(data.subtext)"
          class="gl-m-0 gl-font-sm"
        ></p>
      </div>
    </div>
    <template v-if="data.children && level === 2">
      <ul class="gl-m-0 gl-p-0 gl-list-style-none">
        <li>
          <child-content
            v-for="childData in data.children"
            :key="childData.id"
            :data="childData"
            :widget-label="widgetLabel"
            :level="3"
            data-testid="child-content"
          />
        </li>
      </ul>
    </template>
  </div>
</template>
