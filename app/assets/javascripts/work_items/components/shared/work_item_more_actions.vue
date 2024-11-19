<script>
import {
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlDisclosureDropdownItem,
  GlToggle,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { workItemRoadmapPath } from '../../utils';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '../../constants';

export default {
  i18n: {
    moreActions: s__('WorkItem|More actions'),
    showLabels: s__('WorkItem|Show labels'),
    showClosed: s__('WorkItem|Show closed items'),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
    showClosed: {
      type: Boolean,
      required: false,
      default: true,
    },
    showViewRoadmapAction: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    tooltipText() {
      return !this.isDropdownVisible ? this.$options.i18n.moreActions : '';
    },
    workItemRoadmapPathHref() {
      return workItemRoadmapPath(this.fullPath, this.workItemIid);
    },
    viewOnARoadmap() {
      return {
        text: s__('WorkItem|View on a roadmap'),
        href: this.workItemRoadmapPathHref,
        extraAttrs: {
          'data-testid': 'view-roadmap',
        },
      };
    },
    shouldShowViewRoadmapAction() {
      return (
        this.workItemType.toUpperCase() === WORK_ITEM_TYPE_ENUM_EPIC && this.showViewRoadmapAction
      );
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
  },
};
</script>
<template>
  <div>
    <gl-disclosure-dropdown
      ref="workItemsMoreActions"
      v-gl-tooltip="tooltipText"
      icon="ellipsis_v"
      text-sr-only
      :toggle-text="$options.i18n.moreActions"
      size="small"
      category="tertiary"
      no-caret
      placement="bottom-end"
      :auto-close="false"
      @shown="showDropdown"
      @hidden="hideDropdown"
    >
      <gl-disclosure-dropdown-item
        class="work-item-dropdown-toggle"
        @action="$emit('toggle-show-labels')"
      >
        <template #list-item>
          <gl-toggle
            :value="showLabels"
            :label="$options.i18n.showLabels"
            class="gl-justify-between"
            label-position="left"
          />
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        class="work-item-dropdown-toggle"
        @action="$emit('toggle-show-closed')"
      >
        <template #list-item>
          <gl-toggle
            :value="showClosed"
            :label="$options.i18n.showClosed"
            class="gl-justify-between"
            label-position="left"
          />
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item
        v-if="shouldShowViewRoadmapAction"
        :item="viewOnARoadmap"
        @action="trackEvent('view_epic_on_roadmap')"
      />
    </gl-disclosure-dropdown>
  </div>
</template>
