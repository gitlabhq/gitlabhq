<script>
  /* eslint-disable vue/require-default-prop */
  import Cookies from 'js-cookie';
  import Flash from '~/flash';
  import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
  import sidebarDatePicker from '~/vue_shared/components/sidebar/date_picker.vue';
  import sidebarCollapsedGroupedDatePicker from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';
  import SidebarService from '../services/sidebar_service';
  import Store from '../stores/sidebar_store';

  export default {
    name: 'EpicSidebar',
    components: {
      sidebarDatePicker,
      sidebarCollapsedGroupedDatePicker,
    },
    props: {
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
    },
    data() {
      const store = new Store({
        startDate: this.initialStartDate,
        endDate: this.initialEndDate,
      });

      return {
        store,
        // Backend will pass the appropriate css class for the contentContainer
        collapsed: Cookies.get('collapsed_gutter') === 'true',
        savingStartDate: false,
        savingEndDate: false,
        service: new SidebarService(this.endpoint),
      };
    },
    methods: {
      toggleSidebar() {
        this.collapsed = !this.collapsed;

        const contentContainer = this.$el.closest('.page-with-sidebar');
        contentContainer.classList.toggle('right-sidebar-expanded');
        contentContainer.classList.toggle('right-sidebar-collapsed');

        Cookies.set('collapsed_gutter', this.collapsed);
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
    },
  };
</script>

<template>
  <aside
    class="right-sidebar"
    :class="{ 'right-sidebar-expanded' : !collapsed, 'right-sidebar-collapsed': collapsed }"
  >
    <div class="issuable-sidebar">
      <sidebar-date-picker
        v-if="!collapsed"
        :collapsed="collapsed"
        :is-loading="savingStartDate"
        :editable="editable"
        label="Planned start date"
        :selected-date="store.startDateTime"
        :max-date="store.endDateTime"
        :show-toggle-sidebar="true"
        @saveDate="saveStartDate"
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-date-picker
        v-if="!collapsed"
        :collapsed="collapsed"
        :is-loading="savingEndDate"
        :editable="editable"
        label="Planned finish date"
        :selected-date="store.endDateTime"
        :min-date="store.startDateTime"
        @saveDate="saveEndDate"
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-collapsed-grouped-date-picker
        v-if="collapsed"
        :collapsed="collapsed"
        :min-date="store.startDateTime"
        :max-date="store.endDateTime"
        :show-toggle-sidebar="true"
        @toggleCollapse="toggleSidebar"
      />
    </div>
  </aside>
</template>
