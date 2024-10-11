<script>
import { GlAvatar, GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { isEqual } from 'lodash';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  name: 'TitleArea',
  components: {
    GlAvatar,
    GlSprintf,
    GlLink,
    GlSkeletonLoader,
    PageHeading,
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
  <div class="gl-flex gl-flex-col">
    <page-heading>
      <template #heading>
        <slot name="title">{{ title }}</slot>
        <gl-avatar v-if="avatar" :src="avatar" :shape="$options.AVATAR_SHAPE_OPTION_RECT" />
      </template>

      <template #description>
        <slot name="sub-header"></slot>
        <div v-if="metadataSlots.length > 0" class="gl-flex gl-flex-wrap gl-items-center">
          <template v-if="!metadataLoading">
            <div
              v-for="(row, metadataIndex) in metadataSlots"
              :key="metadataIndex"
              class="gl-mr-5 gl-flex gl-items-center"
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
      </template>

      <template #actions>
        <slot name="right-actions"></slot>
      </template>
    </page-heading>

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
