<script>
import { GlSprintf, GlAlert, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    LocalStorageSync,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    cleanupPoliciesSettingsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      dismissed: false,
    };
  },
  computed: {
    storageKey() {
      return `cleanup_policy_enabled_for_project_${this.projectPath}`;
    },
  },
  i18n: {
    message: s__(
      'ContainerRegistry|Cleanup policies are now available for this project. %{linkStart}Click here to get started.%{linkEnd}',
    ),
  },
};
</script>

<template>
  <local-storage-sync v-model="dismissed" :storage-key="storageKey">
    <gl-alert v-if="!dismissed" class="gl-mt-2" dismissible @dismiss="dismissed = true">
      <gl-sprintf :message="$options.i18n.message">
        <template #link="{ content }">
          <gl-link v-if="cleanupPoliciesSettingsPath" :href="cleanupPoliciesSettingsPath">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </local-storage-sync>
</template>
