<script>
import { sprintf } from '~/locale';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import {
  HARBOR_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  imagesCountInfoText,
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
    helpPagePath: {
      type: String,
      default: '',
      required: false,
    },
    metadataLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    HARBOR_REGISTRY_TITLE,
  },
  computed: {
    imagesCountText() {
      const pluralisedString = imagesCountInfoText(this.imagesCount);
      return sprintf(pluralisedString, { count: this.imagesCount });
    },
    infoMessages() {
      return [{ text: LIST_INTRO_TEXT, link: this.helpPagePath }];
    },
  },
};
</script>

<template>
  <title-area
    :title="$options.i18n.HARBOR_REGISTRY_TITLE"
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
