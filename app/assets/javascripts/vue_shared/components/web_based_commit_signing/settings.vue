<script>
import WebBasedCommitSigningCheckbox from './checkbox.vue';

export default {
  name: 'WebBasedCommitSigningSettings',
  components: {
    WebBasedCommitSigningCheckbox,
  },
  inject: {
    fullPath: { default: null },
    levelId: { default: null },
    groupSettingsRepositoryPath: { default: null },
  },
  props: {
    initialValue: {
      type: Boolean,
      required: true,
    },
    canAdminGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupWebBasedCommitSigningEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroupLevel: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <web-based-commit-signing-checkbox
    :initial-value="initialValue"
    :has-group-permissions="canAdminGroup"
    :group-settings-repository-path="groupSettingsRepositoryPath"
    :is-group-level="isGroupLevel"
    :group-web-based-commit-signing-enabled="groupWebBasedCommitSigningEnabled"
    :full-path="fullPath"
  />
</template>
