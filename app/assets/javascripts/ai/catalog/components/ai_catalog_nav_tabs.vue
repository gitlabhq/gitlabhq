<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
import { AI_CATALOG_AGENTS_ROUTE } from '../router/constants';

export default {
  components: {
    GlTab,
    GlTabs,
  },
  computed: {
    tabs() {
      return [
        {
          text: s__('AICatalog|Agents'),
          route: AI_CATALOG_AGENTS_ROUTE,
        },
      ];
    },
  },
  methods: {
    navigateTo(route) {
      if (this.$route.path !== route) {
        this.$router.push({ name: route });
      }
    },
  },
};
</script>

<template>
  <div class="gl-mb-4 gl-flex lg:gl-items-center">
    <gl-tabs content-class="gl-py-0" class="gl-w-full">
      <gl-tab
        v-for="tab in tabs"
        :key="tab.text"
        :title="tab.text"
        @click="navigateTo(tab.route)"
      />
    </gl-tabs>
  </div>
</template>
