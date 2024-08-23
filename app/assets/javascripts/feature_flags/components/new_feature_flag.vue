<script>
import { GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ROLLOUT_STRATEGY_ALL_USERS } from '../constants';
import FeatureFlagForm from './form.vue';

export default {
  components: {
    FeatureFlagForm,
    GlAlert,
  },
  mixins: [featureFlagsMixin()],
  computed: {
    ...mapState(['error', 'path']),
    strategies() {
      return [{ name: ROLLOUT_STRATEGY_ALL_USERS, parameters: {}, scopes: [] }];
    },
  },
  methods: {
    ...mapActions(['createFeatureFlag']),
  },
};
</script>
<template>
  <div>
    <h1 class="page-title gl-text-size-h-display">{{ s__('FeatureFlags|New feature flag') }}</h1>

    <gl-alert v-if="error.length" variant="warning" class="gl-mb-5" :dismissible="false">
      <p v-for="(message, index) in error" :key="index" class="gl-mb-0">{{ message }}</p>
    </gl-alert>

    <feature-flag-form
      :cancel-path="path"
      :submit-text="s__('FeatureFlags|Create feature flag')"
      :strategies="strategies"
      @handleSubmit="(data) => createFeatureFlag(data)"
    />
  </div>
</template>
