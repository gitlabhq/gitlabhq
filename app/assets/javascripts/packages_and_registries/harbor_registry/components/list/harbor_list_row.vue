<script>
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { getNameFromParams } from '~/packages_and_registries/harbor_registry/utils';

export default {
  name: 'HarborListRow',
  components: {
    ClipboardButton,
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
    linkTo() {
      const { projectName, imageName } = getNameFromParams(this.item.name);

      return { name: 'details', params: { project: projectName, image: imageName } };
    },
    artifactCountText() {
      return n__(
        'HarborRegistry|%d artifact',
        'HarborRegistry|%d artifacts',
        this.item.artifactCount,
      );
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <router-link class="gl-font-bold gl-text-default" data-testid="details-link" :to="linkTo">
        {{ item.name }}
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
        <span class="gl-flex gl-items-center" data-testid="artifacts-count">
          <gl-icon name="package" class="gl-mr-2" />
          {{ artifactCountText }}
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
