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
    url() {
      return this.func.url;
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
    <div class="table-section section-20">{{ name }}</div>
    <div class="table-section section-50">
      <a :href="url">{{ url }}</a>
    </div>
    <div class="table-section section-20">{{ image }}</div>
    <div class="table-section section-10"><timeago :time="timestamp" /></div>
  </div>
</template>
