<script>
import { defineAsyncComponent } from 'vue';
import { GlAlert, GlSprintf, GlToggle } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { __ } from '~/locale';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import FeatureFlagForm from './form.vue';

export default {
  name: 'EditFeatureFlag',
  components: {
    GlAlert,
    GlSprintf,
    GlToggle,
    DetailLayout,
    FeatureFlagActions: defineAsyncComponent(
      () => import('ee_component/feature_flags/components/actions.vue'),
    ),
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
  },
  created() {
    return this.fetchFeatureFlag();
  },
  methods: {
    ...mapActions(['updateFeatureFlag', 'fetchFeatureFlag', 'toggleActive']),
  },
  i18n: {
    title: __('Feature flag %{name}'),
    toggleLabel: __('Status'),
    submit: __('Save changes'),
  },
};
</script>
<template>
  <detail-layout v-if="!hasError" :loading="isLoading">
    <template v-if="!isLoading" #heading>
      <gl-sprintf :message="$options.i18n.title">
        <template #name>
          <span class="gl-rounded-lg gl-bg-strong gl-px-1 gl-font-monospace">{{ name }}</span>
        </template>
      </gl-sprintf>
    </template>

    <template v-if="!isLoading && iid" #description>
      <span class="gl-font-bold gl-text-strong">
        {{ __('ID:') }}
      </span>
      ^{{ iid }}
    </template>

    <template #actions>
      <feature-flag-actions />
    </template>

    <template v-if="error.length" #alerts>
      <gl-alert variant="warning" class="gl-mb-5" :dismissible="false">
        <p v-for="(message, index) in error" :key="index" class="gl-mb-0">{{ message }}</p>
      </gl-alert>
    </template>

    <gl-toggle
      :value="active"
      class="gl-mb-5"
      data-testid="feature-flag-status-toggle"
      data-track-action="click_button"
      data-track-label="feature_flag_toggle"
      :label="$options.i18n.toggleLabel"
      @change="toggleActive"
    />

    <feature-flag-form
      :name="name"
      :description="description"
      :strategies="strategies"
      :cancel-path="path"
      :submit-text="$options.i18n.submit"
      :active="active"
      @handle-submit="(data) => updateFeatureFlag(data)"
    />
  </detail-layout>
</template>
