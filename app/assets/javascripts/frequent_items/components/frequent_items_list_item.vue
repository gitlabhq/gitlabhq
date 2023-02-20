<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { mapVuexModuleState, mapVuexModuleActions } from '~/lib/utils/vuex_module_mappers';
import Tracking from '~/tracking';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlIcon,
    GlButton,
    ProjectAvatar,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
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
    ...mapVuexModuleState((vm) => vm.vuexModule, ['dropdownType', 'isItemsListEditable']),
    truncatedNamespace() {
      return truncateNamespace(this.namespace);
    },
    highlightedItemName() {
      return highlight(this.itemName, this.matcher);
    },
    itemTrackingLabel() {
      return `${this.dropdownType}_dropdown_frequent_items_list_item`;
    },
  },
  methods: {
    removeFrequentItemTracked(item) {
      this.track('click_button', {
        label: `${this.dropdownType}_dropdown_remove_frequent_item`,
        property: 'navigation_top',
      });
      this.removeFrequentItem(item);
    },
    ...mapVuexModuleActions((vm) => vm.vuexModule, ['removeFrequentItem']),
  },
};
</script>

<template>
  <li class="frequent-items-list-item-container gl-relative">
    <gl-button
      category="tertiary"
      :href="webUrl"
      class="gl-text-left gl-w-full"
      button-text-classes="gl-display-flex gl-w-full"
      data-testid="frequent-item-link"
      @click="track('click_link', { label: itemTrackingLabel, property: 'navigation_top' })"
    >
      <div class="gl-flex-grow-1">
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
      </div>
    </gl-button>
    <gl-button
      v-if="isItemsListEditable"
      v-gl-tooltip.left
      size="small"
      category="tertiary"
      :aria-label="__('Remove')"
      :title="__('Remove')"
      class="gl-align-self-center gl-p-1! gl-absolute! gl-w-auto! gl-right-4 gl-top-half gl-translate-y-n50"
      data-testid="item-remove"
      @click.stop.prevent="removeFrequentItemTracked(itemId)"
    >
      <gl-icon name="close" />
    </gl-button>
  </li>
</template>
