<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { workItemRoadmapPath } from '../../utils';

export default {
  i18n: {
    moreActions: s__('WorkItem|More actions'),
  },
  components: {
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
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
    actionDropdownItems() {
      return [
        {
          text: s__('WorkItem|View on a roadmap'),
          href: workItemRoadmapPath(this.fullPath, this.workItemIid),
        },
      ];
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
      :items="actionDropdownItems"
      size="small"
      category="tertiary"
      no-caret
      placement="bottom-end"
      @shown="showDropdown"
      @hidden="hideDropdown"
    />
  </div>
</template>
