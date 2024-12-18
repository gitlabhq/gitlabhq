<script>
import { GlDisclosureDropdown, GlPopover, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import {
  WORK_ITEM_TYPE_VALUE_EPIC,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  sprintfWorkItem,
} from '../../constants';

export default {
  components: {
    GlDisclosureDropdown,
    GlPopover,
    GlLink,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isDropdownVisible: false,
    };
  },
  computed: {
    buttonTooltipText() {
      return this.isDropdownVisible ? '' : this.tooltipText;
    },
  },
  methods: {
    getPopoverText(workItemType) {
      return sprintfWorkItem(
        s__(
          'WorkItem|You cannot add another child %{workItemType}. You’ve reached the maximum number of nested levels.',
        ),
        workItemType,
      );
    },
    getPopoverLink(workItemType) {
      switch (workItemType) {
        case WORK_ITEM_TYPE_VALUE_EPIC:
          return helpPagePath('/user/group/epics/manage_epics', {
            anchor: 'multi-level-child-epics',
          });
        case WORK_ITEM_TYPE_VALUE_OBJECTIVE:
          return helpPagePath('/user/okrs', { anchor: 'child-objectives-and-key-results' });
        default:
          return '';
      }
    },
    onBeforeClose({ originalEvent: { target }, preventDefault }) {
      // Prevents the disclosure dropdown from being closed
      // if clicking on a link within the popover,
      // because the dropdown treats it as a click outside and emits beforeClose event
      // which prevents the user from visiting the link
      if (target?.id === 'info-link') preventDefault();
    },
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
  <gl-disclosure-dropdown
    v-gl-tooltip="buttonTooltipText"
    :toggle-text="__('Add')"
    size="small"
    placement="bottom-end"
    :items="actions"
    @shown="showDropdown"
    @hidden="hideDropdown"
    @beforeClose="onBeforeClose"
  >
    <template #group-label="{ group }">
      <span class="gl-flex gl-items-center gl-justify-between gl-pr-4">
        {{ group.name }}
        <gl-popover v-if="group.atDepthLimit" triggers="hover focus" target="info-icon">
          {{ getPopoverText(group.name) }}
          <gl-link id="info-link" :href="getPopoverLink(group.name)" target="_blank">
            {{ __('Learn more.') }}
          </gl-link>
        </gl-popover>
        <span
          v-if="group.atDepthLimit"
          id="info-icon"
          tabindex="0"
          :aria-label="__(`Help`)"
          class="gl-leading-1"
        >
          <help-icon />
        </span>
      </span>
    </template>
  </gl-disclosure-dropdown>
</template>
