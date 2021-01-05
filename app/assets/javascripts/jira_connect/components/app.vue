<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'JiraConnectApp',
  mixins: [glFeatureFlagsMixin()],
  computed: {
    state() {
      return this.$root.$data.state || {};
    },
    error() {
      return this.state.error;
    },
    showNewUi() {
      return this.glFeatures.newJiraConnectUi;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="showNewUi">
      <h3>{{ s__('Integrations|Linked namespaces') }}</h3>
    </div>
  </div>
</template>
