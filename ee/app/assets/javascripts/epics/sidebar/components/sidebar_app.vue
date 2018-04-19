<script>
  /* global ListLabel */
  /* eslint-disable vue/require-default-prop */
  import Cookies from 'js-cookie';
  import Flash from '~/flash';
  import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
  import SidebarDatePicker from '~/vue_shared/components/sidebar/date_picker.vue';
  import SidebarCollapsedGroupedDatePicker from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';
  import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';
  import SidebarLabelsSelect from '~/vue_shared/components/sidebar/labels_select/base.vue';
  import SidebarService from '../services/sidebar_service';
  import Store from '../stores/sidebar_store';

  export default {
    name: 'EpicSidebar',
    components: {
      ToggleSidebar,
      SidebarDatePicker,
      SidebarCollapsedGroupedDatePicker,
      SidebarLabelsSelect,
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
      initialLabels: {
        type: Array,
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
      });

      return {
        store,
        // Backend will pass the appropriate css class for the contentContainer
        collapsed: Cookies.get('collapsed_gutter') === 'true',
        savingStartDate: false,
        savingEndDate: false,
        service: new SidebarService(this.endpoint),
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
      handleLabelClick(label) {
        if (label.isAny) {
          this.epicContext.labels = [];
        } else {
          const labelIndex = this.epicContext.labels.findIndex(l => l.id === label.id);

          if (labelIndex === -1) {
            this.epicContext.labels.push(new ListLabel({
              id: label.id,
              title: label.title,
              color: label.color[0],
              textColor: label.text_color,
            }));
          } else {
            this.epicContext.labels.splice(labelIndex, 1);
          }
        }
      },
    },
  };
</script>

<template>
  <aside
    class="right-sidebar"
    :class="{ 'right-sidebar-expanded' : !collapsed, 'right-sidebar-collapsed': collapsed }"
  >
    <div class="issuable-sidebar js-issuable-update">
      <div class="block issuable-sidebar-header">
        <toggle-sidebar
          :collapsed="collapsed"
          @toggle="toggleSidebar"
        />
      </div>
      <sidebar-date-picker
        v-if="!collapsed"
        block-class="start-date"
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
        block-class="end-date"
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
        @toggleCollapse="toggleSidebar"
      />
      <sidebar-labels-select
        ability-name="epic"
        :context="epicContext"
        :namespace="namespace"
        :update-path="updatePath"
        :labels-path="labelsPath"
        :labels-web-url="labelsWebUrl"
        :label-filter-base-path="epicsWebUrl"
        :can-edit="editable"
        :show-create="true"
        @onLabelClick="handleLabelClick"
      >
        {{ __('None') }}
      </sidebar-labels-select>
    </div>
  </aside>
</template>
