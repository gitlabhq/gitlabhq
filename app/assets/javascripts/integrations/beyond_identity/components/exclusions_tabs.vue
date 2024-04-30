<script>
import { GlNavItem, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { settingsTabTitle } from '~/integrations/constants';

export default {
  name: 'ExclusionsTabs',
  components: {
    GlNavItem,
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
};
</script>

<template>
  <gl-tabs content-class="gl-p-0">
    <template #tabs-start>
      <gl-nav-item role="presentation" link-classes="gl-tab-nav-item" :href="editPath">{{
        $options.i18n.settingsTabTitle
      }}</gl-nav-item>
    </template>

    <gl-tab active>
      <template #title>
        {{ $options.i18n.projectsTabTitle }}
      </template>
    </gl-tab>
  </gl-tabs>
</template>
