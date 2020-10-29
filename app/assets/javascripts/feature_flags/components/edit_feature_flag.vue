<script>
import { GlAlert, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import axios from '~/lib/utils/axios_utils';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { LEGACY_FLAG, NEW_FLAG_ALERT } from '../constants';
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
    legacyFlagAlert: s__(
      'FeatureFlags|GitLab is moving to a new way of managing feature flags, and in 13.4, this feature flag will become read-only. Please create a new feature flag.',
    ),
    legacyReadOnlyFlagAlert: s__(
      'FeatureFlags|GitLab is moving to a new way of managing feature flags. This feature flag is read-only, and it will be removed in 14.0. Please create a new feature flag.',
    ),
    newFlagAlert: NEW_FLAG_ALERT,
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
      return this.hasNewVersionFlags && this.version === LEGACY_FLAG;
    },
    deprecatedAndEditable() {
      return this.deprecated && !this.hasLegacyReadOnlyFlags;
    },
    deprecatedAndReadOnly() {
      return this.deprecated && this.hasLegacyReadOnlyFlags;
    },
    hasNewVersionFlags() {
      return this.glFeatures.featureFlagsNewVersion;
    },
    hasLegacyReadOnlyFlags() {
      return (
        this.glFeatures.featureFlagsLegacyReadOnly &&
        !this.glFeatures.featureFlagsLegacyReadOnlyOverride
      );
    },
    shouldShowNewFlagAlert() {
      return !this.hasNewVersionFlags && this.userShouldSeeNewFlagAlert;
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
    <gl-alert
      v-if="shouldShowNewFlagAlert"
      variant="warning"
      class="gl-my-5"
      @dismiss="dismissNewVersionFlagAlert"
    >
      {{ $options.translations.newFlagAlert }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-mt-7" />

    <template v-else-if="!isLoading && !hasError">
      <gl-alert v-if="deprecatedAndEditable" variant="warning" :dismissible="false" class="gl-my-5">
        {{ $options.translations.legacyFlagAlert }}
      </gl-alert>
      <gl-alert v-if="deprecatedAndReadOnly" variant="warning" :dismissible="false" class="gl-my-5">
        {{ $options.translations.legacyReadOnlyFlagAlert }}
      </gl-alert>
      <div class="gl-display-flex gl-align-items-center gl-mb-4 gl-mt-4">
        <gl-toggle
          :value="active"
          data-testid="feature-flag-status-toggle"
          data-track-event="click_button"
          data-track-label="feature_flag_toggle"
          class="gl-mr-4"
          @change="toggleActive"
        />
        <h3 class="page-title gl-m-0">{{ title }}</h3>
      </div>

      <div v-if="error.length" class="alert alert-danger">
        <p v-for="(message, index) in error" :key="index" class="gl-mb-0">{{ message }}</p>
      </div>

      <feature-flag-form
        :name="name"
        :description="description"
        :scopes="scopes"
        :strategies="strategies"
        :cancel-path="path"
        :submit-text="__('Save changes')"
        :active="active"
        :version="version"
        @handleSubmit="data => updateFeatureFlag(data)"
      />
    </template>
  </div>
</template>
