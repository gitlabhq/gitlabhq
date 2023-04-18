<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { mapGetters } from 'vuex';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  computed: {
    ...mapGetters('monitoringDashboard', { links: 'linksWithMetadata' }),
  },
};
</script>
<template>
  <div
    ref="linksSection"
    class="gl-sm-display-flex gl-sm-flex-wrap gl-mt-5 gl-p-3 gl-bg-gray-10 border gl-rounded-base links-section"
  >
    <div
      v-for="(link, key) in links"
      :key="key"
      class="gl-mb-1 gl-mr-5 gl-display-flex gl-sm-display-block gl-hover-text-blue-600-children gl-word-break-all"
    >
      <gl-link :href="link.url" class="gl-text-gray-900 gl-text-decoration-none!"
        ><gl-icon name="link" class="gl-text-gray-500 gl-vertical-align-text-bottom gl-mr-2" />{{
          link.title
        }}
      </gl-link>
    </div>
  </div>
</template>
