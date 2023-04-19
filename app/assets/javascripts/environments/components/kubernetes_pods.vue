<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import k8sPodsQuery from '../graphql/queries/k8s_pods.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlSingleStat,
  },
  apollo: {
    k8sPods: {
      query: k8sPodsQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      update(data) {
        return data?.k8sPods || [];
      },
      error(error) {
        this.error = error;
        this.$emit('cluster-error', this.error);
      },
    },
  },
  props: {
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      error: '',
    };
  },

  computed: {
    podStats() {
      if (!this.k8sPods) return null;

      return [
        {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          value: this.getPodsByPhase('Running'),
          title: this.$options.i18n.runningPods,
        },
        {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          value: this.getPodsByPhase('Pending'),
          title: this.$options.i18n.pendingPods,
        },
        {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          value: this.getPodsByPhase('Succeeded'),
          title: this.$options.i18n.succeededPods,
        },
        {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          value: this.getPodsByPhase('Failed'),
          title: this.$options.i18n.failedPods,
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sPods.loading;
    },
  },
  methods: {
    getPodsByPhase(phase) {
      const filteredPods = this.k8sPods.filter((item) => item.status.phase === phase);
      return filteredPods.length;
    },
  },
  i18n: {
    podsTitle: s__('Environment|Pods'),
    runningPods: s__('Environment|Running'),
    pendingPods: s__('Environment|Pending'),
    succeededPods: s__('Environment|Succeeded'),
    failedPods: s__('Environment|Failed'),
  },
};
</script>
<template>
  <div>
    <p class="gl-text-gray-500">{{ $options.i18n.podsTitle }}</p>

    <gl-loading-icon v-if="loading" />

    <div
      v-else-if="podStats && !error"
      class="gl-display-flex gl-flex-wrap gl-sm-flex-nowrap gl-mx-n3 gl-mt-n3"
    >
      <gl-single-stat
        v-for="(stat, index) in podStats"
        :key="index"
        class="gl-w-full gl-flex-direction-column gl-align-items-center gl-justify-content-center gl-bg-white gl-border gl-border-gray-a-08 gl-mx-3 gl-p-3 gl-mt-3"
        :value="stat.value"
        :title="stat.title"
      />
    </div>
  </div>
</template>
