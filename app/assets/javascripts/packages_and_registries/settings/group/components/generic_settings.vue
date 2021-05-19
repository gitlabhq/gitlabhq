<script>
import { s__ } from '~/locale';
import SettingsTitles from '~/packages_and_registries/settings/group/components/settings_titles.vue';

export default {
  name: 'GenericSettings',
  components: {
    SettingsTitles,
  },
  i18n: {
    title: s__('PackageRegistry|Generic'),
    subTitle: s__('PackageRegistry|Settings for Generic packages'),
  },
  modelNames: {
    allowed: 'genericDuplicatesAllowed',
    exception: 'genericDuplicateExceptionRegex',
  },
};
</script>

<template>
  <div>
    <settings-titles :title="$options.i18n.title" :sub-title="$options.i18n.subTitle" />
    <slot :model-names="$options.modelNames"></slot>
  </div>
</template>
