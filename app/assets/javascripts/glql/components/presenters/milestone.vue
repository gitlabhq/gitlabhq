<script>
import { GlLink } from '@gitlab/ui';
import initIssuablePopovers from 'ee_else_ce/issuable/popover';
import { extractGroupOrProject } from '../../utils/common';

export default {
  name: 'MilestonePresenter',
  components: {
    GlLink,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      ...extractGroupOrProject(this.data.webPath),
    };
  },
  mounted() {
    initIssuablePopovers([this.$refs.reference.$el]);
  },
};
</script>
<template>
  <gl-link
    ref="reference"
    data-reference-type="milestone"
    :title="data.title"
    :data-project="project"
    :data-milestone="data.id"
    :href="data.webPath"
    >%{{ data.title }}</gl-link
  >
</template>
