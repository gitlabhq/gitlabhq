<script>
/* eslint-disable vue/require-default-prop, vue/no-v-html */
import { GlButton } from '@gitlab/ui';
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
  mixins: [trackingMixin],
  inject: ['vuexModule'],
  props: {
    matcher: {
      type: String,
      required: false,
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
  },
};
</script>

<template>
  <li class="frequent-items-list-item-container">
    <gl-button
      category="tertiary"
      :href="webUrl"
      class="gl-text-left gl-justify-content-start!"
      @click="track('click_link', { label: `${dropdownType}_dropdown_frequent_items_list_item` })"
    >
      <project-avatar
        class="gl-float-left gl-mr-3"
        :project-avatar-url="avatarUrl"
        :project-name="itemName"
        aria-hidden="true"
      />
      <div ref="frequentItemsItemMetadataContainer" class="frequent-items-item-metadata-container">
        <div
          ref="frequentItemsItemTitle"
          :title="itemName"
          class="frequent-items-item-title"
          v-html="highlightedItemName"
        ></div>
        <div
          v-if="namespace"
          ref="frequentItemsItemNamespace"
          :title="namespace"
          class="frequent-items-item-namespace"
        >
          {{ truncatedNamespace }}
        </div>
      </div>
    </gl-button>
  </li>
</template>
