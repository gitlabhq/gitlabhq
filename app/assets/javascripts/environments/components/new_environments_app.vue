<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import environmentAppQuery from '../graphql/queries/environmentApp.query.graphql';
import EnvironmentFolder from './new_environment_folder.vue';

export default {
  components: {
    EnvironmentFolder,
    GlBadge,
    GlTab,
    GlTabs,
  },
  apollo: {
    environmentApp: {
      query: environmentAppQuery,
    },
  },
  computed: {
    folders() {
      return this.environmentApp?.environments.filter((e) => e.size > 1) ?? [];
    },
    availableCount() {
      return this.environmentApp?.availableCount;
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs>
      <gl-tab>
        <template #title>
          <span>{{ __('Available') }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ availableCount }}
          </gl-badge>
        </template>
        <environment-folder
          v-for="folder in folders"
          :key="folder.name"
          class="gl-mb-3"
          :nested-environment="folder"
        />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
