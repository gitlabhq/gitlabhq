<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { settingsTabTitle } from '~/integrations/constants';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'ExclusionsTabs',
  components: {
    GlTabs,
    GlTab,
  },
  inject: {
    editPath: {
      default: '',
    },
  },
  i18n: {
    settingsTabTitle,
    projectsTabTitle: s__('Integrations|Exclusions'),
  },
  methods: {
    goToSettings() {
      visitUrl(this.editPath);
    },
  },
};
</script>

<template>
  <gl-tabs content-class="gl-p-0">
    <gl-tab :title="$options.i18n.settingsTabTitle" @click="goToSettings" />
    <gl-tab :title="$options.i18n.projectsTabTitle" active />
  </gl-tabs>
</template>
