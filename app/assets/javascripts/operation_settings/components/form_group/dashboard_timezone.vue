<script>
import { mapState, mapActions } from 'vuex';
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import { timezones } from '~/monitoring/format_date';

export default {
  components: {
    GlFormGroup,
    GlFormSelect,
  },
  computed: {
    ...mapState(['dashboardTimezone']),
    dashboardTimezoneModel: {
      get() {
        return this.dashboardTimezone.selected;
      },
      set(selected) {
        this.setDashboardTimezone(selected);
      },
    },
    options() {
      return [
        {
          value: timezones.LOCAL,
          text: s__("MetricsSettings|User's local timezone"),
        },
        {
          value: timezones.UTC,
          text: s__('MetricsSettings|UTC (Coordinated Universal Time)'),
        },
      ];
    },
  },
  methods: {
    ...mapActions(['setDashboardTimezone']),
  },
};
</script>

<template>
  <gl-form-group
    :label="s__('MetricsSettings|Dashboard timezone')"
    label-for="dashboard-timezone-setting"
  >
    <template #description>
      {{
        s__(
          "MetricsSettings|Choose whether to display dashboard metrics in UTC or the user's local timezone.",
        )
      }}
    </template>

    <gl-form-select
      id="dashboard-timezone-setting"
      v-model="dashboardTimezoneModel"
      :options="options"
    />
  </gl-form-group>
</template>
