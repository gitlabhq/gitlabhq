<script>
import { createAlert } from '~/alert';
import { RENDER_ERROR_MSG } from './constants';
import { initLeafletMap } from './utils';

export default {
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      hasError: false,
      loading: true,
    };
  },
  mounted() {
    try {
      initLeafletMap(this.$refs.map, JSON.parse(this.blob.rawTextBlob));
    } catch (error) {
      createAlert({ message: RENDER_ERROR_MSG });
      this.hasError = true;
    }
  },
};
</script>

<template>
  <div v-if="!hasError" ref="map" class="gl-z-0 gl-h-screen" data-testid="map"></div>
</template>
