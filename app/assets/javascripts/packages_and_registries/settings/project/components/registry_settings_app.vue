<script>
import { GlAlert } from '@gitlab/ui';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  SHOW_SETUP_SUCCESS_ALERT,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';
import ContainerExpirationPolicy from './container_expiration_policy.vue';
import PackagesCleanupPolicy from './packages_cleanup_policy.vue';

export default {
  components: {
    ContainerExpirationPolicy,
    GlAlert,
    PackagesCleanupPolicy,
  },
  inject: ['showContainerRegistrySettings', 'showPackageRegistrySettings'],
  i18n: {
    UPDATE_SETTINGS_SUCCESS_MESSAGE,
  },
  data() {
    return {
      showAlert: false,
    };
  },
  mounted() {
    this.checkAlert();
  },
  methods: {
    checkAlert() {
      const showAlert = getParameterByName(SHOW_SETUP_SUCCESS_ALERT);

      if (showAlert) {
        this.showAlert = true;
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
  },
};
</script>

<template>
  <div data-testid="packages-and-registries-project-settings">
    <gl-alert
      v-if="showAlert"
      variant="success"
      class="gl-mt-5"
      dismissible
      @dismiss="showAlert = false"
    >
      {{ $options.i18n.UPDATE_SETTINGS_SUCCESS_MESSAGE }}
    </gl-alert>
    <packages-cleanup-policy v-if="showPackageRegistrySettings" />
    <container-expiration-policy v-if="showContainerRegistrySettings" />
  </div>
</template>
