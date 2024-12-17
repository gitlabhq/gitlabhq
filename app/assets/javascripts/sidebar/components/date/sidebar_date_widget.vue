<script>
import { GlIcon, GlDatepicker, GlTooltipDirective, GlLink, GlPopover } from '@gitlab/ui';
import { createAlert } from '~/alert';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { TYPE_ISSUE } from '~/issues/constants';
import { localeDateFormat, newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import { dateFields, dateTypes, Tracking } from '../../constants';
import { dueDateQueries, startDateQueries } from '../../queries/constants';
import SidebarEditableItem from '../sidebar_editable_item.vue';
import SidebarFormattedDate from './sidebar_formatted_date.vue';
import SidebarInheritDate from './sidebar_inherit_date.vue';

const hideDropdownEvent = new CustomEvent('hiddenGlDropdown', {
  bubbles: true,
});

export default {
  tracking: {
    event: Tracking.editEvent,
    label: Tracking.rightSidebarLabel,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlDatepicker,
    GlLink,
    GlPopover,
    SidebarEditableItem,
    SidebarFormattedDate,
    SidebarInheritDate,
    HelpIcon,
  },
  inject: ['canUpdate'],
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    dateType: {
      type: String,
      required: false,
      default: dateTypes.due,
    },
    issuableType: {
      required: true,
      type: String,
    },
    canInherit: {
      required: false,
      type: Boolean,
      default: false,
    },
    minDate: {
      required: false,
      type: Date,
      default: null,
    },
    maxDate: {
      required: false,
      type: Date,
      default: null,
    },
  },
  data() {
    return {
      issuable: {},
      loading: false,
      tracking: {
        ...this.$options.tracking,
        property: this.dateType === dateTypes.start ? 'startDate' : 'dueDate',
      },
    };
  },
  apollo: {
    issuable: {
      query() {
        return this.dateQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      skip() {
        return !this.iid;
      },
      update(data) {
        return data.workspace?.issuable || {};
      },
      result({ data }) {
        if (!data) {
          return;
        }
        this.$emit(`${this.dateType}Updated`, data.workspace?.issuable?.[this.dateType]);
      },
      error() {
        createAlert({
          message: sprintf(
            __('Something went wrong while setting %{issuableType} %{dateType} date.'),
            {
              issuableType: this.issuableType,
              dateType: this.dateType === dateTypes.start ? 'start' : 'due',
            },
          ),
        });
      },
      subscribeToMore: {
        document() {
          return this.dateQueries[this.issuableType].subscription;
        },
        variables() {
          return {
            issuableId: this.issuableId,
          };
        },
        skip() {
          return this.skipIssueDueDateSubscription;
        },
      },
    },
  },
  computed: {
    dateQueries() {
      return this.dateType === dateTypes.start ? startDateQueries : dueDateQueries;
    },
    dateLabel() {
      return this.dateType === dateTypes.start
        ? this.$options.i18n.startDate
        : this.$options.i18n.dueDate;
    },
    removeDateLabel() {
      return this.dateType === dateTypes.start
        ? this.$options.i18n.removeStartDate
        : this.$options.i18n.removeDueDate;
    },
    dateValue() {
      return this.issuable?.[this.dateType] || null;
    },
    firstDay() {
      return gon.first_day_of_week;
    },
    isLoading() {
      return this.$apollo.queries.issuable.loading || this.loading;
    },
    initialLoading() {
      return this.$apollo.queries.issuable.loading;
    },
    hasDate() {
      return this.dateValue !== null;
    },
    parsedDate() {
      if (!this.hasDate) {
        return null;
      }

      return newDate(this.dateValue);
    },
    formattedDate() {
      if (!this.hasDate) {
        return this.$options.i18n.noDate;
      }

      return localeDateFormat.asDate.format(this.parsedDate);
    },
    workspacePath() {
      return this.issuableType === TYPE_ISSUE
        ? {
            projectPath: this.fullPath,
          }
        : {
            groupPath: this.fullPath,
          };
    },
    dataTestId() {
      return this.dateType === dateTypes.start ? 'sidebar-start-date' : 'sidebar-due-date';
    },
    issuableId() {
      return this.issuable.id;
    },
    skipIssueDueDateSubscription() {
      return this.issuableType !== TYPE_ISSUE || !this.issuableId || this.isLoading;
    },
  },
  methods: {
    epicDatePopoverEl() {
      return this.$refs?.epicDatePopover?.$el;
    },
    closeForm() {
      this.$refs.editable.collapse();
      this.$el.dispatchEvent(hideDropdownEvent);
      this.$emit('closeForm');
    },
    openDatePicker() {
      this.$refs.datePicker.show();
    },
    setFixedDate(isFixed) {
      const date = this.issuable[dateFields[this.dateType].dateFixed];
      this.setDate(date, isFixed);
    },
    setDate(date, isFixed = true) {
      const formattedDate = date ? toISODateFormat(date) : null;
      this.loading = true;
      this.$refs.editable.collapse();
      this.$apollo
        .mutate({
          mutation: this.dateQueries[this.issuableType].mutation,
          variables: {
            input: {
              ...this.workspacePath,
              iid: this.iid,
              ...(this.canInherit
                ? {
                    [dateFields[this.dateType].dateFixed]: isFixed ? formattedDate : undefined,
                    [dateFields[this.dateType].isDateFixed]: isFixed,
                  }
                : {
                    [this.dateType]: formattedDate,
                  }),
            },
          },
        })
        .then(
          ({
            data: {
              issuableSetDate: { errors },
            },
          }) => {
            if (errors.length) {
              createAlert({
                message: errors[0],
              });
            } else {
              this.$emit('closeForm');
            }
          },
        )
        .catch(() => {
          createAlert({
            message: sprintf(
              __('Something went wrong while setting %{issuableType} %{dateType} date.'),
              {
                issuableType: this.issuableType,
                dateType: this.dateType === dateTypes.start ? 'start' : 'due',
              },
            ),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
  i18n: {
    dueDate: __('Due date'),
    startDate: __('Start date'),
    noDate: __('None'),
    removeDueDate: __('remove due date'),
    removeStartDate: __('remove start date'),
    dateHelpValidMessage: __(
      'These dates affect how your epics appear in the roadmap. Set a fixed date or one inherited from the milestones assigned to issues in this epic.',
    ),
    help: __('Help'),
    learnMore: __('Learn more'),
  },
  dateHelpUrl: '/help/user/group/epics/manage_epics.md#start-and-due-date-inheritance',
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="dateLabel"
    :tracking="tracking"
    :loading="isLoading"
    class="block"
    :data-testid="dataTestId"
    @open="openDatePicker"
  >
    <template v-if="canInherit" #title-extra>
      <help-icon
        ref="epicDatePopover"
        class="hide-collapsed gl-ml-3 gl-cursor-pointer"
        tabindex="0"
        :aria-label="$options.i18n.help"
        data-testid="inherit-date-popover"
      />
      <gl-popover :target="epicDatePopoverEl" triggers="focus" placement="left" boundary="viewport">
        <p>{{ $options.i18n.dateHelpValidMessage }}</p>
        <gl-link :href="$options.dateHelpUrl" target="_blank">{{
          $options.i18n.learnMore
        }}</gl-link>
      </gl-popover>
    </template>
    <template #collapsed>
      <div v-gl-tooltip.viewport.left :title="dateLabel" class="sidebar-collapsed-icon">
        <gl-icon :size="16" name="calendar" />
        <span class="gl-px-3 gl-pt-2 gl-text-sm">{{ formattedDate }}</span>
      </div>
      <sidebar-inherit-date
        v-if="canInherit && !initialLoading"
        :issuable="issuable"
        :date-type="dateType"
        :is-loading="isLoading"
        @reset-date="setDate(null)"
        @set-date="setFixedDate"
      />
      <sidebar-formatted-date
        v-else
        :has-date="hasDate"
        :formatted-date="formattedDate"
        :reset-text="removeDateLabel"
        :is-loading="isLoading"
        @reset-date="setDate(null)"
      />
    </template>
    <template #default>
      <gl-datepicker
        v-if="!isLoading"
        ref="datePicker"
        class="gl-relative"
        :value="parsedDate"
        :min-date="minDate"
        :max-date="maxDate"
        :default-date="parsedDate"
        :first-day="firstDay"
        show-clear-button
        autocomplete="off"
        @input="setDate"
        @clear="setDate(null)"
      />
    </template>
  </sidebar-editable-item>
</template>
