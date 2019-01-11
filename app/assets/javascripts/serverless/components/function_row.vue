<script>
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    Timeago,
  },
  props: {
    func: {
      type: Object,
      required: true,
    },
  },
  computed: {
    name() {
      return this.func.name;
    },
    description() {
      return this.func.description;
    },
    detailUrl() {
      return this.func.detail_url;
    },
    environment() {
      return this.func.environment_scope;
    },
    image() {
      return this.func.image;
    },
    timestamp() {
      return this.func.created_at;
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row">
    <div class="table-section section-20 section-wrap">
      <a :href="detailUrl">{{ name }}</a>
    </div>
    <div class="table-section section-10">{{ environment }}</div>
    <div class="table-section section-40 section-wrap">
      <span class="line-break">{{ description }}</span>
    </div>
    <div class="table-section section-20">{{ image }}</div>
    <div class="table-section section-10"><timeago :time="timestamp" /></div>
  </div>
</template>

<style>
.line-break {
  white-space: pre;
}
</style>
