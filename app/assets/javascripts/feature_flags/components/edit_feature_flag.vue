<script>
import { GlAlert, GlLoadingIcon, GlToggle } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { sprintf, __ } from '~/locale';
import FeatureFlagForm from './form.vue';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    GlToggle,
    FeatureFlagActions: () => import('ee_component/feature_flags/components/actions.vue'),
    FeatureFlagForm,
  },
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
        : sprintf(this.$options.i18n.editTitle, { name: this.name });
    },
  },
  created() {
    return this.fetchFeatureFlag();
  },
  methods: {
    ...mapActions(['updateFeatureFlag', 'fetchFeatureFlag', 'toggleActive']),
  },
  i18n: {
    editTitle: __('Edit %{name}'),
    toggleLabel: __('Feature flag status'),
    submit: __('Save changes'),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-mt-7" />

    <template v-else-if="!isLoading && !hasError">
      <div class="gl-mb-4 gl-mt-4 gl-flex gl-items-center">
        <gl-toggle
          :value="active"
          data-testid="feature-flag-status-toggle"
          data-track-action="click_button"
          data-track-label="feature_flag_toggle"
          class="gl-mr-4"
          :label="$options.i18n.toggleLabel"
          label-position="hidden"
          @change="toggleActive"
        />
        <h3 class="page-title gl-m-0">{{ title }}</h3>

        <feature-flag-actions class="gl-ml-auto" />
      </div>

      <gl-alert v-if="error.length" variant="warning" class="gl-mb-5" :dismissible="false">
        <p v-for="(message, index) in error" :key="index" class="gl-mb-0">{{ message }}</p>
      </gl-alert>

      <feature-flag-form
        :name="name"
        :description="description"
        :strategies="strategies"
        :cancel-path="path"
        :submit-text="$options.i18n.submit"
        :active="active"
        @handleSubmit="(data) => updateFeatureFlag(data)"
      />
    </template>
  </div>
</template>
