<script>
import { GlAvatar, GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'TitleArea',
  components: {
    GlAvatar,
    GlSprintf,
    GlLink,
    GlSkeletonLoader,
  },
  props: {
    avatar: {
      type: String,
      default: null,
      required: false,
    },
    title: {
      type: String,
      default: null,
      required: false,
    },
    infoMessages: {
      type: Array,
      default: () => [],
      required: false,
    },
    metadataLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      metadataSlots: [],
    };
  },
  async mounted() {
    const METADATA_PREFIX = 'metadata-';
    this.metadataSlots = Object.keys(this.$slots).filter((k) => k.startsWith(METADATA_PREFIX));

    // we need to wait for next tick to ensure that dynamic names slots are picked up
    await this.$nextTick();
    this.metadataSlots = Object.keys(this.$slots).filter((k) => k.startsWith(METADATA_PREFIX));
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <div class="gl-display-flex gl-justify-content-space-between gl-py-3">
      <div class="gl-flex-direction-column gl-flex-grow-1">
        <div class="gl-display-flex">
          <gl-avatar
            v-if="avatar"
            :src="avatar"
            shape="rect"
            class="gl-align-self-center gl-mr-4"
          />

          <div class="gl-display-flex gl-flex-direction-column">
            <h1 class="gl-font-size-h1 gl-mt-3 gl-mb-2" data-testid="title">
              <slot name="title">{{ title }}</slot>
            </h1>

            <div
              v-if="$slots['sub-header']"
              class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-mt-1"
            >
              <slot name="sub-header"></slot>
            </div>
          </div>
        </div>

        <div class="gl-display-flex gl-flex-wrap gl-align-items-center gl-mt-3">
          <template v-if="!metadataLoading">
            <div
              v-for="(row, metadataIndex) in metadataSlots"
              :key="metadataIndex"
              class="gl-display-flex gl-align-items-center gl-mr-5"
            >
              <slot :name="row"></slot>
            </div>
          </template>
          <template v-else>
            <div class="gl-w-full">
              <gl-skeleton-loader :width="960" :height="16" preserve-aspect-ratio="xMinYMax meet">
                <circle cx="6" cy="8" r="6" />
                <rect x="16" y="4" width="200" height="8" rx="4" />
              </gl-skeleton-loader>
            </div>
          </template>
        </div>
      </div>
      <div v-if="$slots['right-actions']" class="gl-mt-3">
        <slot name="right-actions"></slot>
      </div>
    </div>
    <p>
      <span
        v-for="(message, index) in infoMessages"
        :key="index"
        class="gl-mr-2"
        data-testid="info-message"
      >
        <gl-sprintf :message="message.text">
          <template #docLink="{ content }">
            <gl-link :href="message.link" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </p>
  </div>
</template>
