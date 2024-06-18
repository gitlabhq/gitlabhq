<script>
import { GlCollapse, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import setEnvironmentToChangeCanaryMutation from '../graphql/mutations/set_environment_to_change_canary.mutation.graphql';
import DeployBoard from './deploy_board.vue';

export default {
  components: {
    DeployBoard,
    GlButton,
    GlCollapse,
  },
  props: {
    rolloutStatus: {
      required: true,
      type: Object,
    },
    environment: {
      required: true,
      type: Object,
    },
  },
  data() {
    return { visible: false };
  },
  computed: {
    icon() {
      return this.visible ? 'chevron-lg-down' : 'chevron-lg-right';
    },
    label() {
      return this.visible ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
    isLoading() {
      return this.rolloutStatus.status === 'loading';
    },
    isEmpty() {
      return this.rolloutStatus.status === 'not_found';
    },
  },
  methods: {
    toggleCollapse() {
      this.visible = !this.visible;
    },
    changeCanaryWeight(weight) {
      this.$apollo.mutate({
        mutation: setEnvironmentToChangeCanaryMutation,
        variables: {
          environment: this.environment,
          weight,
        },
      });
    },
  },
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
    pods: s__('DeployBoard|Kubernetes Pods'),
  },
};
</script>
<template>
  <div>
    <div>
      <gl-button
        class="gl-mr-4 gl-min-w-fit"
        :icon="icon"
        :aria-label="label"
        size="small"
        category="tertiary"
        @click="toggleCollapse"
      />
      <span>{{ $options.i18n.pods }}</span>
    </div>
    <gl-collapse :visible="visible">
      <deploy-board
        :deploy-board-data="rolloutStatus"
        :is-loading="isLoading"
        :is-empty="isEmpty"
        :environment="environment"
        graphql
        class="!gl-bg-inherit"
        @changeCanaryWeight="changeCanaryWeight"
      />
    </gl-collapse>
  </div>
</template>
