<script>
import { s__, __ } from '~/locale';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import ChangeUrl from './change_url.vue';

export default {
  name: 'AdvancedSettings',
  components: { SettingsBlock, ChangeUrl },
  i18n: {
    settingsBlock: {
      title: __('Advanced'),
      description: s__('Organization|Perform advanced options such as deleting the organization.'),
    },
  },
};
</script>

<template>
  <settings-block id="organization-settings-advanced" :title="$options.i18n.settingsBlock.title">
    <template #description>{{ $options.i18n.settingsBlock.description }}</template>
    <template #default>
      <change-url />
    </template>
  </settings-block>
</template>
