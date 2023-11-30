<script>
import OrganizationSettings from './organization_settings.vue';
import AdvancedSettings from './advanced_settings.vue';

export default {
  name: 'OrganizationSettingsGeneralApp',
  components: { OrganizationSettings, AdvancedSettings },
};
</script>

<template>
  <div>
    <organization-settings />
    <advanced-settings />
  </div>
</template>
