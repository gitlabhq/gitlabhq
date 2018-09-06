<script>
/* eslint-disable vue/require-default-prop */
import $ from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import flash from '~/flash';
import { __, s__, sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import ListLabel from '~/vue_shared/models/label';
import SidebarTodo from '~/sidebar/components/todo_toggle/todo.vue';
import SidebarCollapsedGroupedDatePicker from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';
import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';
import SidebarLabelsSelect from '~/vue_shared/components/sidebar/labels_select/base.vue';
import SidebarDatePicker from './sidebar_date_picker.vue';
import SidebarParticipants from './sidebar_participants.vue';
import SidebarSubscriptions from './sidebar_subscriptions.vue';
import SidebarService from '../services/sidebar_service';
import Store from '../stores/sidebar_store';

const DateTypes = {
  start: 'start',
  end: 'end',
};

export default {
  name: 'EpicSidebar',
  components: {
    ToggleSidebar,
    SidebarTodo,
    SidebarDatePicker,
    SidebarCollapsedGroupedDatePicker,
    SidebarLabelsSelect,
    SidebarParticipants,
    SidebarSubscriptions,
  },
  props: {
    epicId: {
      type: Number,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialStartDateIsFixed: {
      type: Boolean,
      required: true,
    },
    initialStartDateFixed: {
      type: String,
      required: false,
    },
    startDateFromMilestones: {
      type: String,
      required: false,
    },
    initialStartDate: {
      type: String,
      required: false,
    },
    initialDueDateIsFixed: {
      type: Boolean,
      required: true,
    },
    initialDueDateFixed: {
      type: String,
      required: false,
    },
    dueDateFromMilestones: {
      type: String,
      required: false,
    },
    initialEndDate: {
      type: String,
      required: false,
    },
    startDateSourcingMilestoneTitle: {
      type: String,
      required: false,
      default: '',
    },
    dueDateSourcingMilestoneTitle: {
      type: String,
      required: false,
      default: '',
    },
    initialLabels: {
      type: Array,
      required: true,
    },
    initialParticipants: {
      type: Array,
      required: true,
    },
    initialSubscribed: {
      type: Boolean,
      required: true,
    },
    initialTodoExists: {
      type: Boolean,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
      default: '#',
    },
    updatePath: {
      type: String,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    toggleSubscriptionPath: {
      type: String,
      required: true,
    },
    todoPath: {
      type: String,
      required: true,
    },
    todoDeletePath: {
      type: String,
      required: true,
    },
    labelsWebUrl: {
      type: String,
      required: true,
    },
    epicsWebUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    const store = new Store({
      startDateIsFixed: this.initialStartDateIsFixed,
      startDateFromMilestones: this.startDateFromMilestones,
      startDateFixed: this.initialStartDateFixed,
      startDate: this.initialStartDate,
      dueDateIsFixed: this.initialDueDateIsFixed,
      dueDateFromMilestones: this.dueDateFromMilestones,
      dueDateFixed: this.initialDueDateFixed,
      endDate: this.initialEndDate,
      subscribed: this.initialSubscribed,
      todoExists: this.initialTodoExists,
      todoDeletePath: this.todoDeletePath,
    });

    return {
      store,
      // Backend will pass the appropriate css class for the contentContainer
      collapsed: Cookies.get('collapsed_gutter') === 'true',
      isUserSignedIn: !!gon.current_user_id,
      autoExpanded: false,
      savingStartDate: false,
      savingEndDate: false,
      savingSubscription: false,
      savingTodoAction: false,
      service: new SidebarService({
        endpoint: this.endpoint,
        subscriptionEndpoint: this.subscriptionEndpoint,
        todoPath: this.todoPath,
      }),
      epicContext: {
        labels: this.initialLabels,
      },
    };
  },
  computed: {
    /**
     * This prop determines if epic dates
     * are valid (i.e. given start date is less than given end date)
     */
    isDateValid() {
      const {
        startDateTime,
        startDateTimeFromMilestones,
        startDateIsFixed,
        endDateTime,
        dueDateTimeFromMilestones,
        dueDateIsFixed,
      } = this.store;

      if (startDateIsFixed && dueDateIsFixed) {
        // When Epic start and finish dates are of type fixed.
        return this.getDateValidity(startDateTime, endDateTime);
      } else if (!startDateIsFixed && dueDateIsFixed) {
        // When Epic start date is from milestone and finish date is of type fixed.
        return this.getDateValidity(startDateTimeFromMilestones, endDateTime);
      } else if (startDateIsFixed && !dueDateIsFixed) {
        // When Epic start date is fixed and finish date is from milestone.
        return this.getDateValidity(startDateTime, dueDateTimeFromMilestones);
      }

      // When both Epic start date and finish date are from milestone.
      return this.getDateValidity(startDateTimeFromMilestones, dueDateTimeFromMilestones);
    },
    collapsedSidebarStartDate() {
      return this.store.startDateIsFixed
        ? this.store.startDateTime
        : this.store.startDateTimeFromMilestones;
    },
    collapsedSidebarEndDate() {
      return this.store.dueDateIsFixed
        ? this.store.endDateTime
        : this.store.dueDateTimeFromMilestones;
    },
  },
  methods: {
    getDateValidity(startDate, endDate) {
      // If both dates are defined
      // only then compare, return true otherwise
      if (startDate && endDate) {
        return startDate < endDate;
      }
      return true;
    },
    getDateTypeString(dateType) {
      return dateType === DateTypes.start ? s__('Epics|start') : s__('Epics|finish');
    },
    getDateFromMilestonesTooltip(dateType = 'start') {
      const { startDateTimeFromMilestones, dueDateTimeFromMilestones } = this.store;
      const dateSourcingMilestoneTitle = this[`${dateType}DateSourcingMilestoneTitle`];

      if (startDateTimeFromMilestones && dueDateTimeFromMilestones) {
        return dateSourcingMilestoneTitle;
      }

      return sprintf(s__('Epics|To schedule your epic\'s %{epicDateType} date based on milestones, assign a milestone with a %{epicDateType} date to any issue in the epic.'), {
        epicDateType: this.getDateTypeString(dateType),
      });
    },
    toggleSidebar() {
      this.collapsed = !this.collapsed;

      const contentContainer = this.$el.closest('.page-with-contextual-sidebar');
      contentContainer.classList.toggle('right-sidebar-expanded');
      contentContainer.classList.toggle('right-sidebar-collapsed');

      Cookies.set('collapsed_gutter', this.collapsed);
    },
    toggleSidebarRevealLabelsDropdown() {
      const contentContainer = this.$el.closest('.page-with-contextual-sidebar');
      this.toggleSidebar();
      // When sidebar is expanded, we need to wait
      // for rendering to finish before opening
      // dropdown as otherwise it causes `calc()`
      // used in CSS to miscalculate collapsed
      // sidebar size.
      _.debounce(() => {
        this.autoExpanded = true;
        contentContainer
          .querySelector('.js-sidebar-dropdown-toggle')
          .dispatchEvent(new Event('click', { bubbles: true, cancelable: false }));
      }, 100)();
    },
    saveDate(dateType, newDate, isFixed = true) {
      const type = dateType === DateTypes.start ? dateType : 'end';
      const capitalizedType = capitalizeFirstCharacter(type);
      const serviceMethod = `update${capitalizedType}Date`;
      const savingBoolean = `saving${capitalizedType}Date`;

      this[savingBoolean] = true;

      return this.service[serviceMethod]({
        dateValue: newDate,
        isFixed,
      })
        .then(() => {
          this[savingBoolean] = false;
          this.store[`${type}Date`] = newDate;

          if (isFixed) {
            // Update fixed date in store
            const fixedDate = dateType === DateTypes.start ? 'startDateFixed' : 'dueDateFixed';
            this.store[fixedDate] = newDate;
          }
        })
        .catch(() => {
          this[savingBoolean] = false;
          flash(sprintf(s__('Epics|An error occurred while saving %{epicDateType} date'), {
            epicDateType: this.getDateTypeString(dateType),
          }));
        });
    },
    changeStartDateType(dateTypeIsFixed, typeChangeOnEdit) {
      this.store.startDateIsFixed = dateTypeIsFixed;
      if (!typeChangeOnEdit) {
        this.saveDate(
          DateTypes.start,
          dateTypeIsFixed ? this.store.startDateFixed : this.store.startDateFromMilestones,
          dateTypeIsFixed,
        );
      }
    },
    saveStartDate(date) {
      return this.saveDate(DateTypes.start, date);
    },
    changeEndDateType(dateTypeIsFixed, typeChangeOnEdit) {
      this.store.dueDateIsFixed = dateTypeIsFixed;
      if (!typeChangeOnEdit) {
        this.saveDate(
          DateTypes.end,
          dateTypeIsFixed ? this.store.dueDateFixed : this.store.dueDateFromMilestones,
          dateTypeIsFixed,
        );
      }
    },
    saveEndDate(date) {
      return this.saveDate(DateTypes.end, date);
    },
    saveTodoState({ count, deletePath }) {
      this.savingTodoAction = false;
      this.store.setTodoExists(!this.store.todoExists);
      if (deletePath) {
        this.store.setTodoDeletePath(deletePath);
      }
      $(document).trigger('todo:toggle', count);
    },
    handleLabelClick(label) {
      if (label.isAny) {
        this.epicContext.labels = [];
      } else {
        const labelIndex = this.epicContext.labels.findIndex(l => l.id === label.id);

        if (labelIndex === -1) {
          this.epicContext.labels.push(
            new ListLabel({
              id: label.id,
              title: label.title,
              color: label.color[0],
              textColor: label.text_color,
            }),
          );
        } else {
          this.epicContext.labels.splice(labelIndex, 1);
        }
      }
    },
    handleDropdownClose() {
      if (this.autoExpanded) {
        this.autoExpanded = false;
        this.toggleSidebar();
      }
    },
    handleToggleSubscribed() {
      this.service
        .toggleSubscribed()
        .then(() => {
          this.store.setSubscribed(!this.store.subscribed);
        })
        .catch(() => {
          if (this.store.subscribed) {
            flash(__('An error occurred while unsubscribing to notifications.'));
          } else {
            flash(__('An error occurred while subscribing to notifications.'));
          }
        });
    },
    handleToggleTodo() {
      this.savingTodoAction = true;
      if (!this.store.todoExists) {
        this.service
          .addTodo(this.epicId)
          .then(({ data }) => {
            this.saveTodoState({
              count: data.count,
              deletePath: data.delete_path,
            });
          })
          .catch(() => {
            this.savingTodoAction = false;
            flash(__('There was an error adding a todo.'));
          });
      } else {
        this.service
          .deleteTodo(this.store.todoDeletePath)
          .then(({ data }) => {
            this.saveTodoState({
              count: data.count,
            });
          })
          .catch(() => {
            this.savingTodoAction = false;
            flash(__('There was an error deleting the todo.'));
          });
      }
    },
  },
};
</script>

<template>
  <aside
    :class="{ 'right-sidebar-expanded' : !collapsed, 'right-sidebar-collapsed': collapsed }"
    v-bind="isUserSignedIn ? { 'data-signed-in': true } : {}"
    class="right-sidebar epic-sidebar"
  >
    <div class="issuable-sidebar js-issuable-update">
      <div class="block issuable-sidebar-header">
        <span class="issuable-header-text hide-collapsed float-left">
          {{ __('Todo') }}
        </span>
        <toggle-sidebar
          :collapsed="collapsed"
          css-classes="float-right"
          @toggle="toggleSidebar"
        />
        <sidebar-todo
          v-if="!collapsed"
          :collapsed="collapsed"
          :issuable-id="epicId"
          :is-todo="store.todoExists"
          :is-action-active="savingTodoAction"
          issuable-type="epic"
          @toggleTodo="handleToggleTodo"
        />
      </div>
      <div
        v-if="collapsed"
        class="block todo"
      >
        <sidebar-todo
          :collapsed="collapsed"
          :issuable-id="epicId"
          :is-todo="store.todoExists"
          :is-action-active="savingTodoAction"
          issuable-type="epic"
          @toggleTodo="handleToggleTodo"
        />
      </div>
      <sidebar-date-picker
        v-if="!collapsed"
        :collapsed="collapsed"
        :is-loading="savingStartDate"
        :is-date-invalid="!isDateValid"
        :editable="editable"
        :selected-date-is-fixed="store.startDateIsFixed"
        :selected-date="store.startDateTime"
        :date-fixed="store.startDateTimeFixed"
        :date-from-milestones="store.startDateTimeFromMilestones"
        :date-from-milestones-tooltip="getDateFromMilestonesTooltip('start')"
        :show-toggle-sidebar="!isUserSignedIn"
        :date-picker-label="__('Fixed start date')"
        :label="__('Planned start date')"
        :date-invalid-tooltip="__(`This date is after the planned finish date,
          so this epic won't appear in the roadmap.`)"
        block-class="start-date"
        @saveDate="saveStartDate"
        @toggleDateType="changeStartDateType"
      />
      <sidebar-date-picker
        v-if="!collapsed"
        :collapsed="collapsed"
        :is-loading="savingEndDate"
        :is-date-invalid="!isDateValid"
        :editable="editable"
        :selected-date-is-fixed="store.dueDateIsFixed"
        :selected-date="store.endDateTime"
        :date-fixed="store.dueDateTimeFixed"
        :date-from-milestones="store.dueDateTimeFromMilestones"
        :date-from-milestones-tooltip="getDateFromMilestonesTooltip('due')"
        :date-picker-label="__('Fixed finish date')"
        :label="__('Planned finish date')"
        :date-invalid-tooltip="__(`This date is before the planned start date,
          so this epic won't appear in the roadmap.`)"
        block-class="end-date"
        @saveDate="saveEndDate"
        @toggleDateType="changeEndDateType"
      />
      <sidebar-collapsed-grouped-date-picker
        v-if="collapsed"
        :collapsed="collapsed"
        :min-date="collapsedSidebarStartDate"
        :max-date="collapsedSidebarEndDate"
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-labels-select
        :context="epicContext"
        :namespace="namespace"
        :update-path="updatePath"
        :labels-path="labelsPath"
        :labels-web-url="labelsWebUrl"
        :label-filter-base-path="epicsWebUrl"
        :can-edit="editable"
        :show-create="true"
        ability-name="epic"
        @onLabelClick="handleLabelClick"
        @onDropdownClose="handleDropdownClose"
        @toggleCollapse="toggleSidebarRevealLabelsDropdown"
      >
        {{ __('None') }}
      </sidebar-labels-select>
      <sidebar-participants
        :participants="initialParticipants"
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-subscriptions
        :loading="savingSubscription"
        :subscribed="store.subscribed"
        @toggleSubscription="handleToggleSubscribed"
        @toggleCollapse="toggleSidebar"
      />
    </div>
  </aside>
</template>
