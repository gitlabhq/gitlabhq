<script>
import { GlAlert } from '@gitlab/ui';
import {
  ERROR_UPDATING_SETTINGS,
  SUCCESS_UPDATING_SETTINGS,
} from '~/packages_and_registries/settings/group/constants';
import PackagesSettings from '~/packages_and_registries/settings/group/components/packages_settings.vue';

import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';

export default {
  name: 'GroupSettingsApp',
  components: {
    GlAlert,
    PackagesSettings,
  },
  inject: ['groupPath'],
  apollo: {
    group: {
      query: getGroupPackagesSettingsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
    },
  },
  data() {
    return {
      group: {},
      alertMessage: null,
    };
  },
  computed: {
    packageSettings() {
      return this.group?.packageSettings || {};
    },
    isLoading() {
      return this.$apollo.queries.group.loading;
    },
  },
  methods: {
    dismissAlert() {
      this.alertMessage = null;
    },
    handleSuccess() {
      this.$toast.show(SUCCESS_UPDATING_SETTINGS);
      this.dismissAlert();
    },
    handleError() {
      this.alertMessage = ERROR_UPDATING_SETTINGS;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="alertMessage" variant="warning" class="gl-mt-4" @dismiss="dismissAlert">
      {{ alertMessage }}
    </gl-alert>

    <packages-settings
      :package-settings="packageSettings"
      :is-loading="isLoading"
      @success="handleSuccess"
      @error="handleError"
    />
  </div>
</template>
