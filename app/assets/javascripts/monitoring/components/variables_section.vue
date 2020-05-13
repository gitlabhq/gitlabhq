<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { mergeUrlParams, updateHistory } from '~/lib/utils/url_utility';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  computed: {
    ...mapState('monitoringDashboard', ['promVariables']),
  },
  methods: {
    ...mapActions('monitoringDashboard', ['fetchDashboardData', 'setVariableData']),
    refreshDashboard(event) {
      const { name, value } = event.target;

      if (this.promVariables[name] !== value) {
        const changedVariable = { [name]: value };

        this.setVariableData(changedVariable);

        updateHistory({
          url: mergeUrlParams(this.promVariables, window.location.href),
          title: document.title,
        });

        this.fetchDashboardData();
      }
    },
  },
};
</script>
<template>
  <div ref="variablesSection" class="d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 variables-section">
    <div v-for="(val, key) in promVariables" :key="key" class="mb-1 pr-2 d-flex d-sm-block">
      <gl-form-group :label="key" class="mb-0 flex-grow-1">
        <gl-form-input
          :value="val"
          :name="key"
          @keyup.native.enter="refreshDashboard"
          @blur.native="refreshDashboard"
        />
      </gl-form-group>
    </div>
  </div>
</template>
