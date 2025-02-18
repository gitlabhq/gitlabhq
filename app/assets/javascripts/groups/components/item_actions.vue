<script>
import {
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { COMMON_STR } from '../constants';
import eventHub from '../event_hub';

const { LEAVE_BTN_TITLE, EDIT_BTN_TITLE, REMOVE_BTN_TITLE, OPTIONS_DROPDOWN_TITLE } = COMMON_STR;

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    parentGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    group: {
      type: Object,
      required: true,
    },
    action: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    removeButtonHref() {
      return `${this.group.editPath}#js-remove-group-form`;
    },
    showDangerousActions() {
      return this.group.canRemove || this.group.canLeave;
    },
    editItem() {
      return {
        text: this.$options.i18n.editBtnTitle,
        href: this.group.editPath,
        extraAttrs: {
          'data-testid': `edit-group-${this.group.id}-btn`,
        },
      };
    },
    leaveItem() {
      return {
        text: this.$options.i18n.leaveBtnTitle,
        action: this.onLeaveGroup,
        extraAttrs: {
          class: '!gl-text-danger',
          'data-testid': `leave-group-${this.group.id}-btn`,
        },
      };
    },
    removeItem() {
      return {
        text: this.$options.i18n.removeBtnTitle,
        href: this.removeButtonHref,
        extraAttrs: {
          class: '!gl-text-danger',
          'data-testid': `remove-group-${this.group.id}-btn`,
        },
      };
    },
  },
  methods: {
    onLeaveGroup() {
      eventHub.$emit(`${this.action}showLeaveGroupModal`, this.group, this.parentGroup);
    },
  },
  i18n: {
    leaveBtnTitle: LEAVE_BTN_TITLE,
    editBtnTitle: EDIT_BTN_TITLE,
    removeBtnTitle: REMOVE_BTN_TITLE,
    optionsDropdownTitle: OPTIONS_DROPDOWN_TITLE,
  },
};
</script>

<template>
  <div class="gl-ml-5 gl-flex gl-justify-end" @click.stop>
    <gl-disclosure-dropdown
      v-gl-tooltip.hover.focus="$options.i18n.optionsDropdownTitle"
      icon="ellipsis_v"
      category="tertiary"
      no-caret
      text-sr-only
      :toggle-text="__('More actions')"
      :data-testid="`group-${group.id}-dropdown-button`"
      :data-qa-group-id="group.id"
    >
      <gl-disclosure-dropdown-item v-if="group.canEdit" :item="editItem" />
      <gl-disclosure-dropdown-group v-if="showDangerousActions" bordered>
        <gl-disclosure-dropdown-item v-if="group.canLeave" :item="leaveItem" />
        <gl-disclosure-dropdown-item v-if="group.canRemove" :item="removeItem" />
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
  </div>
</template>
