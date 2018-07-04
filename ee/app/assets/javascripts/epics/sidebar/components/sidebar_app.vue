<script>
/* eslint-disable vue/require-default-prop */
import $ from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import Flash from '~/flash';
import { __ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import ListLabel from '~/vue_shared/models/label';
import SidebarTodo from '~/sidebar/components/todo_toggle/todo.vue';
import SidebarDatePicker from '~/vue_shared/components/sidebar/date_picker.vue';
import SidebarCollapsedGroupedDatePicker from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';
import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';
import SidebarLabelsSelect from '~/vue_shared/components/sidebar/labels_select/base.vue';
import SidebarParticipants from './sidebar_participants.vue';
import SidebarSubscriptions from './sidebar_subscriptions.vue';
import SidebarService from '../services/sidebar_service';
import Store from '../stores/sidebar_store';

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
    initialStartDate: {
      type: String,
      required: false,
    },
    initialEndDate: {
      type: String,
      required: false,
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
      startDate: this.initialStartDate,
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
  methods: {
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
    saveDate(dateType = 'start', newDate) {
      const type = dateType === 'start' ? dateType : 'end';
      const capitalizedType = capitalizeFirstCharacter(type);
      const serviceMethod = `update${capitalizedType}Date`;
      const savingBoolean = `saving${capitalizedType}Date`;

      this[savingBoolean] = true;

      return this.service[serviceMethod](newDate)
        .then(() => {
          this[savingBoolean] = false;
          this.store[`${type}Date`] = newDate;
        })
        .catch(() => {
          this[savingBoolean] = false;
          Flash(`An error occurred while saving ${type} date`);
        });
    },
    saveStartDate(date) {
      return this.saveDate('start', date);
    },
    saveEndDate(date) {
      return this.saveDate('end', date);
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
            Flash(__('An error occurred while unsubscribing to notifications.'));
          } else {
            Flash(__('An error occurred while subscribing to notifications.'));
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
            Flash(__('There was an error adding a todo.'));
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
            Flash(__('There was an error deleting the todo.'));
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
    class="right-sidebar"
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
        :editable="editable"
        :selected-date="store.startDateTime"
        :max-date="store.endDateTime"
        :show-toggle-sidebar="!isUserSignedIn"
        block-class="start-date"
        label="Planned start date"
        @saveDate="saveStartDate"
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-date-picker
        v-if="!collapsed"
        :collapsed="collapsed"
        :is-loading="savingEndDate"
        :editable="editable"
        :selected-date="store.endDateTime"
        :min-date="store.startDateTime"
        block-class="end-date"
        label="Planned finish date"
        @saveDate="saveEndDate"
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-collapsed-grouped-date-picker
        v-if="collapsed"
        :collapsed="collapsed"
        :min-date="store.startDateTime"
        :max-date="store.endDateTime"
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
