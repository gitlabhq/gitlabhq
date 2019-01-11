<script>
import PodBox from './pod_box.vue';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
    PodBox,
    ClipboardButton,
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
      <div v-for="line in description.split('\n')" :key="line">{{ line }}<br /></div>
    </div>
    <div class="clipboard-group append-bottom-default">
      <div class="label label-monospace">{{ funcUrl }}</div>
      <clipboard-button
        :text="String(funcUrl)"
        :title="s__('ServerlessDetails|Copy URL to clipboard')"
        class="input-group-text js-clipboard-btn"
      />
      <a
        :href="funcUrl"
        target="_blank"
        rel="noopener noreferrer nofollow"
        class="input-group-text btn btn-default"
      >
        <icon name="external-link" />
      </a>
    </div>

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
