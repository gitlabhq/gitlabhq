<script>
import PodBox from './pod_box.vue';
import Url from './url.vue';

export default {
  components: {
    PodBox,
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
      return this.func.description;
    },
    funcUrl() {
      return this.func.url;
    },
    podCount() {
      return this.func.podcount || 0;
    },
  },
};
</script>

<template>
  <section id="serverless-function-details">
    <h3>{{ name }}</h3>
    <div class="append-bottom-default">
      <div v-for="(line, index) in description.split('\n')" :key="index">{{ line }}</div>
    </div>
    <url :uri="funcUrl" />

    <h4>{{ s__('ServerlessDetails|Kubernetes Pods') }}</h4>
    <div v-if="podCount > 0">
      <p>
        <b v-if="podCount == 1">{{ podCount }} {{ s__('ServerlessDetails|pod in use') }}</b>
        <b v-else>{{ podCount }} {{ s__('ServerlessDetails|pods in use') }}</b>
      </p>
      <pod-box :count="podCount" />
      <p>
        {{
          s__('ServerlessDetails|Number of Kubernetes pods in use over time based on necessity.')
        }}
      </p>
    </div>
    <div v-else><p>No pods loaded at this time.</p></div>
  </section>
</template>
