<script>
import { GlLink, GlIntersperse } from '@gitlab/ui';
import initIssuablePopovers from 'ee_else_ce/issuable/popover';
import { extractGroupOrProject } from '../../utils/common';

const types = {
  Issue: 'issue',
  Epic: 'epic',
  MergeRequest: 'merge_request',
};

export default {
  name: 'IssuablePresenter',
  components: {
    GlLink,
    GlIntersperse,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      ...extractGroupOrProject(this.data.webUrl),
    };
  },
  computed: {
    type() {
      // eslint-disable-next-line no-underscore-dangle
      return types[this.data.__typename];
    },
  },
  async mounted() {
    await this.$nextTick();
    initIssuablePopovers([this.$refs.reference.$el]);
  },
  methods: {
    truncateText(text, length = 50) {
      return text.length > length ? `${text.substring(0, length - 3)}...` : text;
    },
  },
};
</script>
<template>
  <gl-link
    ref="reference"
    :data-reference-type="type"
    :title="data.title"
    :href="data.webUrl"
    :data-iid="data.iid"
    :data-project-path="project"
    :data-group-path="group"
  >
    <gl-intersperse separator="">
      <span>{{ truncateText(data.title) }}</span>
      <span> ({{ data.reference }}</span>
      <span v-if="data.state === 'closed'"> - {{ __('closed') }}</span>
      <span v-if="data.state === 'merged'"> - {{ __('merged') }}</span>
      <span>)</span>
    </gl-intersperse>
  </gl-link>
</template>
