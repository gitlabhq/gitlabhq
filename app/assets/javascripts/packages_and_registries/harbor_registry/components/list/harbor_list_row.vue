<script>
import { GlIcon, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { n__ } from '~/locale';

import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';

export default {
  name: 'HarborListRow',
  components: {
    ClipboardButton,
    GlSprintf,
    GlIcon,
    ListItem,
    GlSkeletonLoader,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    metadataLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    id() {
      return this.item.id;
    },
    artifactCountText() {
      return n__(
        'HarborRegistry|%{count} Tag',
        'HarborRegistry|%{count} Tags',
        this.item.artifactCount,
      );
    },
    imageName() {
      return this.item.name;
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <router-link
        class="gl-text-body gl-font-weight-bold"
        data-testid="details-link"
        data-qa-selector="registry_image_content"
        :to="{ name: 'details', params: { id } }"
      >
        {{ imageName }}
      </router-link>
      <clipboard-button
        v-if="item.location"
        :text="item.location"
        :title="item.location"
        category="tertiary"
      />
    </template>
    <template #left-secondary>
      <template v-if="!metadataLoading">
        <span class="gl-display-flex gl-align-items-center" data-testid="tags-count">
          <gl-icon name="tag" class="gl-mr-2" />
          <gl-sprintf :message="artifactCountText">
            <template #count>
              {{ item.artifactCount }}
            </template>
          </gl-sprintf>
        </span>
      </template>

      <div v-else class="gl-w-full">
        <gl-skeleton-loader :width="900" :height="16" preserve-aspect-ratio="xMinYMax meet">
          <circle cx="6" cy="8" r="6" />
          <rect x="16" y="4" width="100" height="8" rx="4" />
        </gl-skeleton-loader>
      </div>
    </template>
  </list-item>
</template>
