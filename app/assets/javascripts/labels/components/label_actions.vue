<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import updateLabelMutation from '~/labels/graphql/update_label.mutation.graphql';
import { TYPENAME_LABEL } from '~/graphql_shared/constants';
import eventHub, {
  EVENT_OPEN_DELETE_LABEL_MODAL,
  EVENT_OPEN_PROMOTE_LABEL_MODAL,
  EVENT_ARCHIVE_LABEL_SUCCESS,
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
    isArchived: {
      type: Boolean,
      required: false,
      default: false,
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
    labelsArchiveEnabled() {
      return Boolean(window.gon?.features?.labelsArchive);
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

      if (this.labelsArchiveEnabled) {
        items.push({
          text: this.$options.i18n[this.isArchived ? 'unarchive' : 'archive'],
          action: this.onToggleArchive,
          extraAttrs: {
            'data-testid': 'toggle-archive-label-action',
          },
        });
      }

      items.push({
        text: this.$options.i18n.delete,
        action: this.onDelete,
        variant: 'danger',
        extraAttrs: {
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
    async onToggleArchive() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateLabelMutation,
          variables: {
            input: {
              id: convertToGraphQLId(TYPENAME_LABEL, this.labelId),
              archived: !this.isArchived,
            },
          },
        });

        if (data?.labelUpdate?.errors?.length) {
          throw new Error(data.labelUpdate.errors.join(', '));
        }

        eventHub.$emit(EVENT_ARCHIVE_LABEL_SUCCESS, this.labelId);

        const toastText = this.isArchived
          ? this.$options.i18n.unarchiveSuccess
          : this.$options.i18n.archiveSuccess;

        this.$toast.show(toastText);
      } catch (error) {
        this.$toast.show(this.$options.i18n.archiveError);

        captureException({ error, component: this.$options.name });
      }
    },
  },
  i18n: {
    edit: __('Edit'),
    delete: __('Delete'),
    archive: __('Archive'),
    unarchive: __('Unarchive'),
    labelActions: s__('Labels|Label actions'),
    labelActionsDropdown: s__('Labels|Label actions dropdown'),
    promoteToGroup: s__('Labels|Promote to group label'),
    archiveError: s__('Labels|An error occurred while archiving the label.'),
    archiveSuccess: s__('Labels|Label archived.'),
    unarchiveSuccess: s__('Labels|Label unarchived.'),
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
