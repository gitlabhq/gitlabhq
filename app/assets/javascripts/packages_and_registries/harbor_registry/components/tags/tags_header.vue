<script>
import { isEmpty } from 'lodash';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
  EMPTY_TAG_LABEL,
  tagsCountText,
} from '~/packages_and_registries/harbor_registry/constants';

export default {
  name: 'TagsHeader',
  components: {
    TitleArea,
    MetadataItem,
  },
  mixins: [timeagoMixin],
  props: {
    artifactDetail: {
      type: Object,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    tagsLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tagCountText() {
      if (isEmpty(this.pageInfo)) {
        return EMPTY_TAG_LABEL;
      }
      return tagsCountText(this.pageInfo.total);
    },
  },
};
</script>

<template>
  <title-area :metadata-loading="tagsLoading">
    <template #title>
      <span class="gl-break-all" data-testid="title">
        {{ artifactDetail.digest }}
      </span>
    </template>
    <template #metadata-tags-count>
      <metadata-item icon="tag" :text="tagCountText" data-testid="tags-count" />
    </template>
  </title-area>
</template>
