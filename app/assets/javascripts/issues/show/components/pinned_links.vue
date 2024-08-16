<script>
import { GlButton } from '@gitlab/ui';
import { STATUS_PAGE_PUBLISHED, JOIN_ZOOM_MEETING } from '../constants';

export default {
  components: {
    GlButton,
  },
  props: {
    zoomMeetingUrl: {
      type: String,
      required: false,
      default: '',
    },
    publishedIncidentUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    pinnedLinks() {
      const links = [];
      if (this.publishedIncidentUrl) {
        links.push({
          id: 'publishedIncidentUrl',
          url: this.publishedIncidentUrl,
          text: STATUS_PAGE_PUBLISHED,
          icon: 'tanuki',
        });
      }
      if (this.zoomMeetingUrl) {
        links.push({
          id: 'zoomMeetingUrl',
          url: this.zoomMeetingUrl,
          text: JOIN_ZOOM_MEETING,
          icon: 'brand-zoom',
        });
      }

      return links;
    },
  },
  methods: {
    needsPaddingClass(i) {
      return i < this.pinnedLinks.length - 1;
    },
  },
};
</script>

<template>
  <div v-if="pinnedLinks && pinnedLinks.length" class="gl-flex gl-justify-start">
    <template v-for="(link, i) in pinnedLinks">
      <div v-if="link.url" :key="link.id" :class="{ 'gl-pr-3': needsPaddingClass(i) }">
        <gl-button
          :href="link.url"
          target="_blank"
          :icon="link.icon"
          size="small"
          class="gl-mb-5 gl-font-bold"
          :data-testid="link.id"
          >{{ link.text }}</gl-button
        >
      </div>
    </template>
  </div>
</template>
