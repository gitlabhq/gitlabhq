<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

import { FETCH_SETTINGS_ERROR_MESSAGE } from '../../shared/constants';

import SettingsForm from './settings_form.vue';

export default {
  components: {
    SettingsForm,
    GlAlert,
    GlSprintf,
    GlLink,
  },
  i18n: {
    unavailableFeatureTitle: s__(
      `ContainerRegistry|Container Registry tag expiration and retention policy is disabled`,
    ),
    unavailableFeatureIntroText: s__(
      `ContainerRegistry|The Container Registry tag expiration and retention policies for this project have not been enabled.`,
    ),
    unavailableUserFeatureText: s__(`ContainerRegistry|Please contact your administrator.`),
    unavailableAdminFeatureText: s__(
      `ContainerRegistry| Please visit the %{linkStart}administration settings%{linkEnd} to enable this feature.`,
    ),
    fetchSettingsErrorText: FETCH_SETTINGS_ERROR_MESSAGE,
  },
  data() {
    return {
      fetchSettingsError: false,
    };
  },
  computed: {
    ...mapState(['isAdmin', 'adminSettingsPath']),
    ...mapGetters({ isDisabled: 'getIsDisabled' }),
    showSettingForm() {
      return !this.isDisabled && !this.fetchSettingsError;
    },
    showDisabledFormMessage() {
      return this.isDisabled && !this.fetchSettingsError;
    },
    unavailableFeatureMessage() {
      return this.isAdmin
        ? this.$options.i18n.unavailableAdminFeatureText
        : this.$options.i18n.unavailableUserFeatureText;
    },
  },
  mounted() {
    this.fetchSettings().catch(() => {
      this.fetchSettingsError = true;
    });
  },
  methods: {
    ...mapActions(['fetchSettings']),
  },
};
</script>

<template>
  <div>
    <p>
      {{ s__('ContainerRegistry|Tag expiration policy is designed to:') }}
    </p>
    <ul>
      <li>{{ s__('ContainerRegistry|Keep and protect the images that matter most.') }}</li>
      <li>
        {{
          s__(
            "ContainerRegistry|Automatically remove extra images that aren't designed to be kept.",
          )
        }}
      </li>
    </ul>
    <settings-form v-if="showSettingForm" />
    <template v-else>
      <gl-alert
        v-if="showDisabledFormMessage"
        :dismissible="false"
        :title="$options.i18n.unavailableFeatureTitle"
        variant="tip"
      >
        {{ $options.i18n.unavailableFeatureIntroText }}

        <gl-sprintf :message="unavailableFeatureMessage">
          <template #link="{ content }">
            <gl-link :href="adminSettingsPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
      <gl-alert v-else-if="fetchSettingsError" variant="warning" :dismissible="false">
        <gl-sprintf :message="$options.i18n.fetchSettingsErrorText" />
      </gl-alert>
    </template>
  </div>
</template>
