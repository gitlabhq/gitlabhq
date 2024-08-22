<script>
import OrganizationSettings from './organization_settings.vue';
import VisibilityLevel from './visibility_level.vue';
import AdvancedSettings from './advanced_settings.vue';

export default {
  name: 'OrganizationSettingsGeneralApp',
  components: { OrganizationSettings, VisibilityLevel, AdvancedSettings },
};
</script>

<template>
  <div class="gl-pt-5">
    <organization-settings />
    <visibility-level />
    <advanced-settings />
  </div>
</template>
