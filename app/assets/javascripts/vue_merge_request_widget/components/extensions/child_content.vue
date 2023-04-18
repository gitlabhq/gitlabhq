<script>
import { GlBadge, GlLink, GlModalDirective } from '@gitlab/ui';
import { isArray } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Actions from '../action_buttons.vue';
import StatusIcon from './status_icon.vue';
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
    SafeHtml,
    GlModal: GlModalDirective,
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
    modalId: {
      type: String,
      required: false,
      default: null,
    },
    level: {
      type: Number,
      required: true,
    },
  },
  computed: {
    subtext() {
      const { subtext } = this.data;
      if (subtext) {
        if (isArray(subtext)) {
          return subtext.map((t) => generateText(t)).join('<br />');
        }

        return generateText(subtext);
      }

      return null;
    },
  },
  methods: {
    isArray(arr) {
      return Array.isArray(arr);
    },
    onClickedAction(action) {
      this.$emit('clickedAction', action);
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
      <div v-if="data.icon" class="report-block-child-icon gl-display-flex">
        <status-icon :icon-name="data.icon.name" :size="12" class="gl-m-auto" />
      </div>
      <div class="gl-w-full">
        <div class="gl-display-flex gl-flex-nowrap">
          <div class="gl-flex-wrap gl-display-flex gl-w-full">
            <div class="gl-display-flex gl-align-items-center">
              <p v-safe-html="generateText(data.text)" class="gl-m-0"></p>
            </div>
            <div v-if="data.link" class="gl-pr-2">
              <gl-link :href="data.link.href">{{ data.link.text }}</gl-link>
            </div>
            <div v-if="data.modal" class="gl-pr-2">
              <gl-link v-gl-modal="modalId" data-testid="modal-link" @click="data.modal.onClick">
                {{ data.modal.text }}
              </gl-link>
            </div>
            <div v-if="data.supportingText">
              <p v-safe-html="generateText(data.supportingText)" class="gl-m-0"></p>
            </div>
            <gl-badge
              v-if="data.badge"
              :variant="data.badge.variant || 'info'"
              size="sm"
              class="gl-ml-2"
            >
              {{ data.badge.text }}
            </gl-badge>
          </div>
          <actions
            :widget="widgetLabel"
            :tertiary-buttons="data.actions"
            class="gl-ml-auto gl-pl-3"
            @clickedAction="onClickedAction"
          />
        </div>
        <p v-if="subtext" v-safe-html="subtext" class="gl-m-0 gl-font-sm"></p>
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
            :modal-id="modalId"
            :level="3"
            data-testid="child-content"
            data-qa-selector="child_content"
            @clickedAction="onClickedAction"
          />
        </li>
      </ul>
    </template>
  </div>
</template>
