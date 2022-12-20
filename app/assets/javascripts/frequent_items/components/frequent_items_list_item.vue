<script>
import { GlButton } from '@gitlab/ui';
import { snakeCase } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { mapVuexModuleState } from '~/lib/utils/vuex_module_mappers';
import Tracking from '~/tracking';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlButton,
    ProjectAvatar,
  },
  directives: {
    SafeHtml,
  },
  mixins: [trackingMixin],
  inject: ['vuexModule'],
  props: {
    matcher: {
      type: String,
      required: false,
      default: '',
    },
    itemId: {
      type: Number,
      required: true,
    },
    itemName: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
      default: '',
    },
    webUrl: {
      type: String,
      required: true,
    },
    avatarUrl: {
      required: true,
      validator(value) {
        return value === null || typeof value === 'string';
      },
    },
  },
  computed: {
    ...mapVuexModuleState((vm) => vm.vuexModule, ['dropdownType']),
    truncatedNamespace() {
      return truncateNamespace(this.namespace);
    },
    highlightedItemName() {
      return highlight(this.itemName, this.matcher);
    },
    itemTrackingLabel() {
      return `${this.dropdownType}_dropdown_frequent_items_list_item_${snakeCase(this.itemName)}`;
    },
  },
};
</script>

<template>
  <li class="frequent-items-list-item-container">
    <gl-button
      category="tertiary"
      :href="webUrl"
      class="gl-text-left gl-justify-content-start!"
      @click="track('click_link', { label: itemTrackingLabel })"
    >
      <project-avatar
        class="gl-float-left gl-mr-3"
        :project-avatar-url="avatarUrl"
        :project-id="itemId"
        :project-name="itemName"
        aria-hidden="true"
      />
      <div
        data-testid="frequent-items-item-metadata-container"
        class="frequent-items-item-metadata-container"
      >
        <div
          v-safe-html="highlightedItemName"
          data-testid="frequent-items-item-title"
          :title="itemName"
          class="frequent-items-item-title"
        ></div>
        <div
          v-if="namespace"
          data-testid="frequent-items-item-namespace"
          :title="namespace"
          class="frequent-items-item-namespace"
        >
          {{ truncatedNamespace }}
        </div>
      </div>
    </gl-button>
  </li>
</template>
