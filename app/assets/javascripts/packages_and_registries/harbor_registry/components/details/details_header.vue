<script>
import { isEmpty } from 'lodash';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
  ROOT_IMAGE_TEXT,
  EMPTY_ARTIFACTS_LABEL,
  artifactsLabel,
} from '~/packages_and_registries/harbor_registry/constants/index';

export default {
  name: 'DetailsHeader',
  components: { TitleArea, MetadataItem },
  mixins: [timeagoMixin],
  props: {
    imagesDetail: {
      type: Object,
      required: true,
    },
  },
  computed: {
    artifactCountText() {
      if (isEmpty(this.imagesDetail)) {
        return EMPTY_ARTIFACTS_LABEL;
      }
      return artifactsLabel(this.imagesDetail.artifactCount);
    },
    repositoryFullName() {
      return this.imagesDetail.name || ROOT_IMAGE_TEXT;
    },
  },
};
</script>

<template>
  <title-area>
    <template #title>
      <span data-testid="title">
        {{ repositoryFullName }}
      </span>
    </template>
    <template #metadata-tags-count>
      <metadata-item icon="package" :text="artifactCountText" data-testid="artifacts-count" />
    </template>
  </title-area>
</template>
