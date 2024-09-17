<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { settingsTabTitle, overridesTabTitle } from '~/integrations/constants';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    GlBadge,
    GlTabs,
    GlTab,
  },
  inject: {
    editPath: {
      default: '',
    },
  },
  props: {
    projectOverridesCount: {
      type: [Number, String],
      required: false,
      default: null,
    },
  },
  i18n: {
    settingsTabTitle,
    overridesTabTitle,
  },
  methods: {
    goToSettings() {
      visitUrl(this.editPath);
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title="$options.i18n.settingsTabTitle" @click="goToSettings" />

    <gl-tab active>
      <template #title>
        {{ $options.i18n.overridesTabTitle }}
        <gl-badge
          v-if="projectOverridesCount !== null"
          variant="muted"
          class="gl-tab-counter-badge"
          >{{ projectOverridesCount }}</gl-badge
        >
      </template>
    </gl-tab>
  </gl-tabs>
</template>
