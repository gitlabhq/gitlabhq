<script>
import { GlTooltipDirective, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { COMMON_STR } from '../constants';
import eventHub from '../event_hub';

const { LEAVE_BTN_TITLE, EDIT_BTN_TITLE, REMOVE_BTN_TITLE, OPTIONS_DROPDOWN_TITLE } = COMMON_STR;

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
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
  <div class="gl-display-flex gl-justify-content-end gl-ml-5">
    <gl-dropdown
      v-gl-tooltip.hover.focus="$options.i18n.optionsDropdownTitle"
      right
      category="tertiary"
      icon="ellipsis_v"
      no-caret
      :data-testid="`group-${group.id}-dropdown-button`"
      data-qa-selector="group_dropdown_button"
      :data-qa-group-id="group.id"
    >
      <gl-dropdown-item
        v-if="group.canEdit"
        :data-testid="`edit-group-${group.id}-btn`"
        :href="group.editPath"
        @click.stop
      >
        {{ $options.i18n.editBtnTitle }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="group.canLeave"
        :data-testid="`leave-group-${group.id}-btn`"
        @click.stop="onLeaveGroup"
      >
        {{ $options.i18n.leaveBtnTitle }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-if="group.canRemove"
        :href="removeButtonHref"
        :data-testid="`remove-group-${group.id}-btn`"
        variant="danger"
        @click.stop
      >
        {{ $options.i18n.removeBtnTitle }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
