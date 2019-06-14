<script>
import { GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
    GlLink,
  },
  props: {
    descriptionHtml: {
      type: String,
      required: true,
    },
  },
  computed: {
    linksInDescription() {
      const el = document.createElement('div');
      el.innerHTML = this.descriptionHtml;
      return [...el.querySelectorAll('a')].map(a => a.href);
    },
    // Detect links matching the following formats:
    // Zoom Start links: https://zoom.us/s/<meeting-id>
    // Zoom Join links: https://zoom.us/j/<meeting-id>
    // Personal Zoom links: https://zoom.us/my/<meeting-id>
    // Vanity Zoom links: https://gitlab.zoom.us/j/<meeting-id> (also /s and /my)
    zoomHref() {
      const zoomRegex = /^https:\/\/([\w\d-]+\.)?zoom\.us\/(s|j|my)\/.+/;
      return this.linksInDescription.reduce((acc, currentLink) => {
        let lastLink = acc;
        if (zoomRegex.test(currentLink)) {
          lastLink = currentLink;
        }
        return lastLink;
      }, '');
    },
  },
};
</script>

<template>
  <div v-if="zoomHref" class="border-bottom mb-3 mt-n2">
    <gl-link
      :href="zoomHref"
      target="_blank"
      class="btn btn-inverted btn-secondary btn-sm text-dark mb-3"
    >
      <icon name="brand-zoom" :size="14" />
      <strong class="vertical-align-top">{{ __('Join Zoom meeting') }}</strong>
    </gl-link>
  </div>
</template>
