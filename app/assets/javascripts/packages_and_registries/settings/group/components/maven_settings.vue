<script>
import { s__ } from '~/locale';
import SettingsTitles from '~/packages_and_registries/settings/group/components/settings_titles.vue';

export default {
  name: 'MavenSettings',
  components: {
    SettingsTitles,
  },
  i18n: {
    title: s__('PackageRegistry|Maven'),
    subTitle: s__('PackageRegistry|Settings for Maven packages'),
  },
  modelNames: {
    allowed: 'mavenDuplicatesAllowed',
    exception: 'mavenDuplicateExceptionRegex',
  },
};
</script>

<template>
  <div>
    <settings-titles :title="$options.i18n.title" :sub-title="$options.i18n.subTitle" />
    <slot :model-names="$options.modelNames"></slot>
  </div>
</template>
