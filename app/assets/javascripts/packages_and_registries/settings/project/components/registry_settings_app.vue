<script>
import { GlAlert } from '@gitlab/ui';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  SHOW_SETUP_SUCCESS_ALERT,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PackageRegistrySection from '~/packages_and_registries/settings/project/components/package_registry_section.vue';
import ContainerRegistrySection from '~/packages_and_registries/settings/project/components/container_registry_section.vue';

export default {
  components: {
    ContainerRegistrySection,
    GlAlert,
    MetadataDatabaseAlert,
    PackageRegistrySection,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'showContainerRegistrySettings',
    'showPackageRegistrySettings',
    'isContainerRegistryMetadataDatabaseEnabled',
  ],
  i18n: {
    UPDATE_SETTINGS_SUCCESS_MESSAGE,
  },
  data() {
    return {
      containerRegistrySectionExpanded: false,
      showAlert: false,
    };
  },
  created() {
    this.checkAlert();
  },
  methods: {
    checkAlert() {
      const showAlert = getParameterByName(SHOW_SETUP_SUCCESS_ALERT);

      if (showAlert) {
        this.showAlert = true;
        this.containerRegistrySectionExpanded = true;
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
  },
};
</script>

<template>
  <div
    data-testid="packages-and-registries-project-settings"
    class="js-hide-when-nothing-matches-search"
  >
    <gl-alert
      v-if="showAlert"
      variant="success"
      class="gl-mt-5"
      dismissible
      @dismiss="showAlert = false"
    >
      {{ $options.i18n.UPDATE_SETTINGS_SUCCESS_MESSAGE }}
    </gl-alert>
    <metadata-database-alert v-if="!isContainerRegistryMetadataDatabaseEnabled" class="gl-mt-5" />
    <package-registry-section v-if="showPackageRegistrySettings" />
    <container-registry-section
      v-if="showContainerRegistrySettings"
      :expanded="containerRegistrySectionExpanded"
    />
  </div>
</template>
