<script>
import { GlSprintf } from '@gitlab/ui';
import { sprintf } from '~/locale';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { DETAILS_PAGE_TITLE, UPDATED_AT } from '../../constants/index';

export default {
  name: 'DetailsHeader',
  components: { GlSprintf, TitleArea, MetadataItem },
  mixins: [timeagoMixin],
  props: {
    image: {
      type: Object,
      required: true,
    },
  },
  computed: {
    visibilityIcon() {
      return this.image?.project?.visibility === 'public' ? 'eye' : 'eye-slash';
    },
    timeAgo() {
      return this.timeFormatted(this.image.updatedAt);
    },
    updatedText() {
      return sprintf(UPDATED_AT, { time: this.timeAgo });
    },
  },
  i18n: {
    DETAILS_PAGE_TITLE,
  },
};
</script>

<template>
  <title-area>
    <template #title>
      <gl-sprintf :message="$options.i18n.DETAILS_PAGE_TITLE">
        <template #imageName>
          {{ image.name }}
        </template>
      </gl-sprintf>
    </template>
    <template #metadata-updated>
      <metadata-item
        :icon="visibilityIcon"
        :text="updatedText"
        size="xl"
        data-testid="updated-and-visibility"
      />
    </template>
  </title-area>
</template>
