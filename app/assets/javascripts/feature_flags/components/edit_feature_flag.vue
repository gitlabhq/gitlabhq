<script>
import { GlAlert, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import axios from '~/lib/utils/axios_utils';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { LEGACY_FLAG } from '../constants';
import FeatureFlagForm from './form.vue';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    GlToggle,
    FeatureFlagForm,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    showUserCallout: {},
    userCalloutId: {
      default: '',
    },
    userCalloutsPath: {
      default: '',
    },
  },
  data() {
    return {
      userShouldSeeNewFlagAlert: this.showUserCallout,
    };
  },
  translations: {
    legacyReadOnlyFlagAlert: s__(
      'FeatureFlags|GitLab is moving to a new way of managing feature flags. This feature flag is read-only, and it will be removed in 14.0. Please create a new feature flag.',
    ),
  },
  computed: {
    ...mapState([
      'path',
      'error',
      'name',
      'description',
      'scopes',
      'strategies',
      'isLoading',
      'hasError',
      'iid',
      'active',
      'version',
    ]),
    title() {
      return this.iid
        ? `^${this.iid} ${this.name}`
        : sprintf(s__('Edit %{name}'), { name: this.name });
    },
    deprecated() {
      return this.version === LEGACY_FLAG;
    },
  },
  created() {
    return this.fetchFeatureFlag();
  },
  methods: {
    ...mapActions(['updateFeatureFlag', 'fetchFeatureFlag', 'toggleActive']),
    dismissNewVersionFlagAlert() {
      this.userShouldSeeNewFlagAlert = false;
      axios.post(this.userCalloutsPath, {
        feature_name: this.userCalloutId,
      });
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-mt-7" />

    <template v-else-if="!isLoading && !hasError">
      <gl-alert v-if="deprecated" variant="warning" :dismissible="false" class="gl-my-5">{{
        $options.translations.legacyReadOnlyFlagAlert
      }}</gl-alert>
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
        :scopes="scopes"
        :strategies="strategies"
        :cancel-path="path"
        :submit-text="__('Save changes')"
        :active="active"
        :version="version"
        @handleSubmit="(data) => updateFeatureFlag(data)"
      />
    </template>
  </div>
</template>
