<script>
import { GlAlert, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import FeatureFlagForm from './form.vue';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    GlToggle,
    FeatureFlagForm,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    ...mapState([
      'path',
      'error',
      'name',
      'description',
      'strategies',
      'isLoading',
      'hasError',
      'iid',
      'active',
    ]),
    title() {
      return this.iid
        ? `^${this.iid} ${this.name}`
        : sprintf(s__('Edit %{name}'), { name: this.name });
    },
  },
  created() {
    return this.fetchFeatureFlag();
  },
  methods: {
    ...mapActions(['updateFeatureFlag', 'fetchFeatureFlag', 'toggleActive']),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-mt-7" />

    <template v-else-if="!isLoading && !hasError">
      <div class="gl-display-flex gl-align-items-center gl-mb-4 gl-mt-4">
        <gl-toggle
          :value="active"
          data-testid="feature-flag-status-toggle"
          data-track-event="click_button"
          data-track-label="feature_flag_toggle"
          class="gl-mr-4"
          :label="__('Feature flag status')"
          label-position="hidden"
          @change="toggleActive"
        />
        <h3 class="page-title gl-m-0">{{ title }}</h3>
      </div>

      <gl-alert v-if="error.length" variant="warning" class="gl-mb-5" :dismissible="false">
        <p v-for="(message, index) in error" :key="index" class="gl-mb-0">{{ message }}</p>
      </gl-alert>

      <feature-flag-form
        :name="name"
        :description="description"
        :strategies="strategies"
        :cancel-path="path"
        :submit-text="__('Save changes')"
        :active="active"
        @handleSubmit="(data) => updateFeatureFlag(data)"
      />
    </template>
  </div>
</template>
