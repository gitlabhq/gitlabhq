<script>
import { GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import { ROLLOUT_STRATEGY_ALL_USERS } from '../constants';
import FeatureFlagForm from './form.vue';

export default {
  name: 'NewFeatureFlag',
  components: {
    DetailLayout,
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
  <detail-layout :heading="s__('FeatureFlags|New feature flag')">
    <template v-if="error.length" #alerts>
      <gl-alert variant="warning" :dismissible="false">
        <p v-for="(message, index) in error" :key="index" class="gl-mb-0">{{ message }}</p>
      </gl-alert>
    </template>

    <feature-flag-form
      :cancel-path="path"
      :submit-text="s__('FeatureFlags|Create feature flag')"
      :strategies="strategies"
      @handle-submit="(data) => createFeatureFlag(data)"
    />
  </detail-layout>
</template>
