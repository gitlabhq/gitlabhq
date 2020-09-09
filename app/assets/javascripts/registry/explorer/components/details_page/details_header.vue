<script>
import { GlSprintf } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { DETAILS_PAGE_TITLE } from '../../constants/index';

export default {
  components: { GlSprintf, TitleArea },
  props: {
    imageName: {
      type: String,
      required: false,
      default: '',
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
          {{ imageName }}
        </template>
      </gl-sprintf>
    </template>
  </title-area>
</template>
