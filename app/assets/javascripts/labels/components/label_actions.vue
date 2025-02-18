<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import eventHub, {
  EVENT_OPEN_DELETE_LABEL_MODAL,
  EVENT_OPEN_PROMOTE_LABEL_MODAL,
} from '../event_hub';

export default {
  name: 'LabelActions',
  components: {
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    labelId: {
      type: String,
      required: true,
    },
    labelName: {
      type: String,
      required: true,
    },
    labelColor: {
      type: String,
      required: true,
    },
    labelTextColor: {
      type: String,
      required: true,
    },
    subjectName: {
      type: String,
      required: false,
      default: '',
    },
    editPath: {
      type: String,
      required: true,
    },
    promotePath: {
      type: String,
      required: false,
      default: '',
    },
    groupName: {
      type: String,
      required: false,
      default: '',
    },
    destroyPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isTooltipVisible: true,
    };
  },
  computed: {
    tooltipTitle() {
      return this.isTooltipVisible ? this.$options.i18n.labelActions : '';
    },
    actionItems() {
      const items = [
        {
          text: this.$options.i18n.edit,
          href: this.editPath,
        },
      ];

      if (this.promotePath) {
        items.push({
          text: this.$options.i18n.promoteToGroup,
          action: this.onPromote,
          extraAttrs: {
            'data-testid': 'promote-label-action',
          },
        });
      }
      items.push({
        text: this.$options.i18n.delete,
        action: this.onDelete,
        extraAttrs: {
          class: '!gl-text-red-500',
          'data-testid': `delete-label-action`,
        },
      });
      return items;
    },
  },
  methods: {
    onShow() {
      this.isTooltipVisible = false;
    },
    onHide() {
      this.isTooltipVisible = true;
    },
    onDelete() {
      eventHub.$emit(EVENT_OPEN_DELETE_LABEL_MODAL, {
        labelId: this.labelId,
        labelName: this.labelName,
        subjectName: this.subjectName,
        destroyPath: this.destroyPath,
      });
    },
    onPromote() {
      eventHub.$emit(EVENT_OPEN_PROMOTE_LABEL_MODAL, {
        labelTitle: this.labelName,
        labelColor: this.labelColor,
        labelTextColor: this.labelTextColor,
        url: this.promotePath,
        groupName: this.groupName,
      });
    },
  },
  i18n: {
    edit: __('Edit'),
    delete: __('Delete'),
    labelActions: s__('Labels|Label actions'),
    labelActionsDropdown: s__('Labels|Label actions dropdown'),
    promoteToGroup: s__('Labels|Promote to group label'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip="tooltipTitle"
    :toggle-text="$options.i18n.labelActionsDropdown"
    text-sr-only
    toggle-class="btn-sm"
    class="gl-ml-3"
    icon="ellipsis_v"
    category="tertiary"
    data-testid="label-actions-dropdown-toggle"
    no-caret
    :items="actionItems"
    @shown="onShow"
    @hidden="onHide"
  />
</template>
