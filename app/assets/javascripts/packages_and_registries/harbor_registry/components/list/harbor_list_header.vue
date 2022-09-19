<script>
import { sprintf } from '~/locale';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import {
  HARBOR_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  imagesCountInfoText,
  HARBOR_REGISTRY_HELP_PAGE_PATH,
} from '~/packages_and_registries/harbor_registry/constants';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';

export default {
  name: 'HarborListHeader',
  components: {
    TitleArea,
    MetadataItem,
  },
  props: {
    imagesCount: {
      type: Number,
      default: 0,
      required: false,
    },
    metadataLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    harborRegistryTitle: HARBOR_REGISTRY_TITLE,
  },
  computed: {
    imagesCountText() {
      const pluralisedString = imagesCountInfoText(this.imagesCount);
      return sprintf(pluralisedString, { count: this.imagesCount });
    },
    infoMessages() {
      return [{ text: LIST_INTRO_TEXT, link: HARBOR_REGISTRY_HELP_PAGE_PATH }];
    },
  },
};
</script>

<template>
  <title-area
    :title="$options.i18n.harborRegistryTitle"
    :info-messages="infoMessages"
    :metadata-loading="metadataLoading"
  >
    <template #right-actions>
      <slot name="commands"></slot>
    </template>
    <template #metadata-count>
      <metadata-item
        v-if="imagesCount"
        data-testid="images-count"
        icon="container-image"
        :text="imagesCountText"
      />
    </template>
  </title-area>
</template>
