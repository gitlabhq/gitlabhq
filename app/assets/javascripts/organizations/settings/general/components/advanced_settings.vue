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
  props: {
    id: {
      type: String,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <settings-block
    :id="id"
    :expanded="expanded"
    :title="$options.i18n.settingsBlock.title"
    @toggle-expand="$emit('toggle-expand', $event)"
  >
    <template #description>{{ $options.i18n.settingsBlock.description }}</template>
    <template #default>
      <change-url />
    </template>
  </settings-block>
</template>
