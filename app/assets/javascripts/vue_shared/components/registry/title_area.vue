<script>
import { GlAvatar, GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

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
  created() {
    this.recalculateMetadataSlots();
  },
  updated() {
    this.recalculateMetadataSlots();
  },
  methods: {
    recalculateMetadataSlots() {
      const METADATA_PREFIX = 'metadata-';
      const metadataSlots = Object.keys(this.$scopedSlots).filter((k) =>
        k.startsWith(METADATA_PREFIX),
      );

      if (!isEqual(metadataSlots, this.metadataSlots)) {
        this.metadataSlots = metadataSlots;
      }
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <div
      class="gl-display-flex gl-flex-wrap gl-sm-flex-nowrap gl-justify-content-space-between gl-py-3"
    >
      <div class="gl-flex-direction-column gl-flex-grow-1 gl-min-w-0">
        <div class="gl-display-flex">
          <gl-avatar
            v-if="avatar"
            :src="avatar"
            :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            class="gl-align-self-center gl-mr-4"
          />

          <div class="gl-display-flex gl-flex-direction-column gl-min-w-0">
            <h2 class="gl-font-size-h1 gl-mt-3 gl-mb-0" data-testid="title">
              <slot name="title">{{ title }}</slot>
            </h2>

            <div
              v-if="$scopedSlots['sub-header']"
              class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-mt-3"
            >
              <slot name="sub-header"></slot>
            </div>
          </div>
        </div>

        <div
          v-if="metadataSlots.length > 0"
          class="gl-display-flex gl-flex-wrap gl-align-items-center gl-mt-3"
        >
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
      <div
        v-if="$scopedSlots['right-actions']"
        class="gl-display-flex gl-align-items-flex-start gl-gap-3 gl-mt-3"
      >
        <slot name="right-actions"></slot>
      </div>
    </div>
    <p v-if="infoMessages.length">
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
    <slot></slot>
  </div>
</template>
