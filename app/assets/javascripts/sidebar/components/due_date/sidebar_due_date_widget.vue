<script>
import { GlButton, GlIcon, GlDatepicker, GlTooltipDirective } from '@gitlab/ui';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import { dateInWords, formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { dueDateQueries } from '~/sidebar/constants';

const hideDropdownEvent = new CustomEvent('hiddenGlDropdown', {
  bubbles: true,
});

export default {
  tracking: {
    event: 'click_edit_button',
    label: 'right_sidebar',
    property: 'dueDate',
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlIcon,
    GlDatepicker,
    SidebarEditableItem,
  },
  inject: ['fullPath', 'iid', 'canUpdate'],
  props: {
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      dueDate: null,
      loading: false,
    };
  },
  apollo: {
    dueDate: {
      query() {
        return dueDateQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable?.dueDate || null;
      },
      result({ data }) {
        this.$emit('dueDateUpdated', data.workspace?.issuable?.dueDate);
      },
      error() {
        createFlash({
          message: sprintf(__('Something went wrong while setting %{issuableType} due date.'), {
            issuableType: this.issuableType,
          }),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.dueDate.loading || this.loading;
    },
    hasDueDate() {
      return this.dueDate !== null;
    },
    parsedDueDate() {
      if (!this.hasDueDate) {
        return null;
      }

      return parsePikadayDate(this.dueDate);
    },
    formattedDueDate() {
      if (!this.hasDueDate) {
        return this.$options.i18n.noDueDate;
      }

      return dateInWords(this.parsedDueDate, true);
    },
    workspacePath() {
      return this.issuableType === IssuableType.Issue
        ? {
            projectPath: this.fullPath,
          }
        : {
            groupPath: this.fullPath,
          };
    },
  },
  methods: {
    closeForm() {
      this.$refs.editable.collapse();
      this.$el.dispatchEvent(hideDropdownEvent);
      this.$emit('closeForm');
    },
    openDatePicker() {
      this.$refs.datePicker.calendar.show();
    },
    setDueDate(date) {
      this.loading = true;
      this.$refs.editable.collapse();
      this.$apollo
        .mutate({
          mutation: dueDateQueries[this.issuableType].mutation,
          variables: {
            input: {
              ...this.workspacePath,
              iid: this.iid,
              dueDate: date ? formatDate(date, 'yyyy-mm-dd') : null,
            },
          },
        })
        .then(
          ({
            data: {
              issuableSetDueDate: { errors },
            },
          }) => {
            if (errors.length) {
              createFlash({
                message: errors[0],
              });
            } else {
              this.$emit('closeForm');
            }
          },
        )
        .catch(() => {
          createFlash({
            message: sprintf(__('Something went wrong while setting %{issuableType} due date.'), {
              issuableType: this.issuableType,
            }),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
  i18n: {
    dueDate: __('Due date'),
    noDueDate: __('None'),
    removeDueDate: __('remove due date'),
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="$options.i18n.dueDate"
    :tracking="$options.tracking"
    :loading="isLoading"
    class="block"
    data-testid="due-date"
    @open="openDatePicker"
  >
    <template #collapsed>
      <div v-gl-tooltip :title="$options.i18n.dueDate" class="sidebar-collapsed-icon">
        <gl-icon :size="16" name="calendar" />
        <span class="collapse-truncated-title">{{ formattedDueDate }}</span>
      </div>
      <div class="gl-display-flex gl-align-items-center hide-collapsed">
        <span
          :class="hasDueDate ? 'gl-text-gray-900 gl-font-weight-bold' : 'gl-text-gray-500'"
          data-testid="sidebar-duedate-value"
        >
          {{ formattedDueDate }}
        </span>
        <div v-if="hasDueDate && canUpdate" class="gl-display-flex">
          <span class="gl-px-2">-</span>
          <gl-button
            variant="link"
            class="gl-text-gray-500!"
            data-testid="reset-button"
            :disabled="isLoading"
            @click="setDueDate(null)"
          >
            {{ $options.i18n.removeDueDate }}
          </gl-button>
        </div>
      </div>
    </template>
    <template #default>
      <gl-datepicker
        ref="datePicker"
        :value="parsedDueDate"
        show-clear-button
        @input="setDueDate"
        @clear="setDueDate(null)"
      />
    </template>
  </sidebar-editable-item>
</template>
