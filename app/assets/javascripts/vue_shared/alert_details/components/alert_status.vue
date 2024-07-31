<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import updateAlertStatusMutation from '~/graphql_shared/mutations/alert_status_update.mutation.graphql';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { PAGE_CONFIG } from '../constants';

export default {
  i18n: {
    UPDATE_ALERT_STATUS_ERROR: s__(
      'AlertManagement|There was an error while updating the status of the alert.',
    ),
    UPDATE_ALERT_STATUS_INSTRUCTION: s__('AlertManagement|Please try again.'),
    ASSIGN_STATUS_HEADER: s__('AlertManagement|Assign status'),
  },
  components: {
    GlCollapsibleListbox,
  },
  inject: {
    trackAlertStatusUpdateOptions: {
      default: null,
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    alert: {
      type: Object,
      required: true,
    },
    isDropdownShowing: {
      type: Boolean,
      required: false,
    },
    isSidebar: {
      type: Boolean,
      required: true,
    },
    statuses: {
      type: Object,
      required: false,
      default: () => PAGE_CONFIG.OPERATIONS.STATUSES,
    },
  },
  data() {
    return {
      alertStatus: this.alert.status,
    };
  },
  computed: {
    dropdownClass() {
      return this.isSidebar && !this.isDropdownShowing ? 'gl-hidden' : '';
    },
    items() {
      return Object.entries(this.statuses).map(([value, text]) => ({ value, text }));
    },
    headerText() {
      return this.isSidebar ? this.$options.i18n.ASSIGN_STATUS_HEADER : '';
    },
  },
  methods: {
    updateAlertStatus(status) {
      this.$emit('handle-updating', true);
      this.$apollo
        .mutate({
          mutation: updateAlertStatusMutation,
          variables: {
            iid: this.alert.iid,
            status,
            projectPath: this.projectPath,
          },
        })
        .then((resp) => {
          if (this.trackAlertStatusUpdateOptions) {
            this.trackStatusUpdate(this.statuses[status]);
          }
          const errors = resp.data?.updateAlertStatus?.errors || [];

          if (errors[0]) {
            this.$emit(
              'alert-error',
              `${this.$options.i18n.UPDATE_ALERT_STATUS_ERROR} ${errors[0]}`,
            );
          }

          this.$emit('hide-dropdown');
        })
        .catch(() => {
          this.$emit(
            'alert-error',
            `${this.$options.i18n.UPDATE_ALERT_STATUS_ERROR} ${this.$options.i18n.UPDATE_ALERT_STATUS_INSTRUCTION}`,
          );
        })
        .finally(() => {
          this.$emit('handle-updating', false);
        });
    },
    trackStatusUpdate(status) {
      const { category, action, label } = this.trackAlertStatusUpdateOptions;
      Tracking.event(category, action, { label, property: status });
    },
  },
};
</script>

<template>
  <div class="dropdown dropdown-menu-selectable" :class="dropdownClass">
    <gl-collapsible-listbox
      ref="dropdown"
      v-model="alertStatus"
      placement="bottom-end"
      :header-text="headerText"
      :items="items"
      block
      @hidden="$emit('hide-dropdown')"
      @select="updateAlertStatus"
    />
  </div>
</template>
