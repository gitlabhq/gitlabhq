<script>
import { mapState, mapActions } from 'vuex';
import { GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  computed: {
    ...mapState(['externalDashboard']),
    userDashboardUrl: {
      get() {
        return this.externalDashboard.url;
      },
      set(url) {
        this.setExternalDashboardUrl(url);
      },
    },
  },
  methods: {
    ...mapActions(['setExternalDashboardUrl']),
  },
};
</script>

<template>
  <gl-form-group
    :label="s__('MetricsSettings|External dashboard URL')"
    label-for="external-dashboard-url"
  >
    <template #description>
      {{
        s__(
          'MetricsSettings|Add a button to the metrics dashboard linking directly to your existing external dashboard.',
        )
      }}
    </template>
    <!-- placeholder with a url is a false positive  -->
    <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
    <gl-form-input
      id="external-dashboard-url"
      v-model="userDashboardUrl"
      placeholder="https://my-org.gitlab.io/my-dashboards"
    />
    <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
  </gl-form-group>
</template>
