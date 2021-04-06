<script>
import { GlButton, GlDatepicker } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import createFlash from '~/flash';
import { dateInWords, formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

export default {
  components: {
    BoardEditableItem,
    GlButton,
    GlDatepicker,
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    ...mapGetters(['activeBoardItem', 'projectPathForActiveIssue']),
    hasDueDate() {
      return this.activeBoardItem.dueDate != null;
    },
    parsedDueDate() {
      if (!this.hasDueDate) {
        return null;
      }

      return parsePikadayDate(this.activeBoardItem.dueDate);
    },
    formattedDueDate() {
      if (!this.hasDueDate) {
        return '';
      }

      return dateInWords(this.parsedDueDate, true);
    },
  },
  methods: {
    ...mapActions(['setActiveIssueDueDate']),
    async openDatePicker() {
      await this.$nextTick();
      this.$refs.datePicker.calendar.show();
    },
    async setDueDate(date) {
      this.loading = true;
      this.$refs.sidebarItem.collapse();

      try {
        const dueDate = date ? formatDate(date, 'yyyy-mm-dd') : null;
        await this.setActiveIssueDueDate({ dueDate, projectPath: this.projectPathForActiveIssue });
      } catch (e) {
        createFlash({ message: this.$options.i18n.updateDueDateError });
      } finally {
        this.loading = false;
      }
    },
  },
  i18n: {
    dueDate: __('Due date'),
    removeDueDate: __('remove due date'),
    updateDueDateError: __('An error occurred when updating the issue due date'),
  },
};
</script>

<template>
  <board-editable-item
    ref="sidebarItem"
    class="board-sidebar-due-date"
    data-testid="sidebar-due-date"
    :title="$options.i18n.dueDate"
    :loading="loading"
    @open="openDatePicker"
  >
    <template v-if="hasDueDate" #collapsed>
      <div class="gl-display-flex gl-align-items-center">
        <strong class="gl-text-gray-900">{{ formattedDueDate }}</strong>
        <span class="gl-mx-2">-</span>
        <gl-button
          variant="link"
          class="gl-text-gray-500!"
          data-testid="reset-button"
          :disabled="loading"
          @click="setDueDate(null)"
        >
          {{ $options.i18n.removeDueDate }}
        </gl-button>
      </div>
    </template>
    <gl-datepicker
      ref="datePicker"
      :value="parsedDueDate"
      show-clear-button
      @input="setDueDate"
      @clear="setDueDate(null)"
    />
  </board-editable-item>
</template>
<style>
/*
 * This can be removed after closing:
 * https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1048
 */
.board-sidebar-due-date .gl-datepicker,
.board-sidebar-due-date .gl-datepicker-input {
  width: 100%;
}
</style>
