<script>
import { isString } from 'lodash';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import Url from './url.vue';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    Timeago,
    Url,
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
      if (!isString(this.func.description)) {
        return '';
      }

      const desc = this.func.description.split('\n');
      if (desc.length > 1) {
        return desc[1];
      }

      return desc[0];
    },
    detailUrl() {
      return this.func.detail_url;
    },
    targetUrl() {
      return this.func.url;
    },
    image() {
      return this.func.image;
    },
    timestamp() {
      return this.func.created_at;
    },
  },
  methods: {
    checkClass(element) {
      if (element.closest('.no-expand') === null) {
        return true;
      }

      return false;
    },
    openDetails(e) {
      if (this.checkClass(e.target)) {
        visitUrl(this.detailUrl);
      }
    },
  },
};
</script>

<template>
  <li :id="name" class="group-row">
    <div class="group-row-contents py-2" role="button" @click="openDetails">
      <p class="float-right text-right">
        <span>{{ image }}</span
        ><br />
        <timeago :time="timestamp" />
      </p>
      <b>{{ name }}</b>
      <div v-for="line in description.split('\n')" :key="line">{{ line }}</div>
      <url :uri="targetUrl" class="gl-mt-3 no-expand" />
    </div>
  </li>
</template>
