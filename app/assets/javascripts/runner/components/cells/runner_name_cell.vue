<script>
import { GlLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  components: {
    GlLink,
    TooltipOnTruncate,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    runnerNumericalId() {
      return getIdFromGraphQLId(this.runner.id);
    },
    runnerUrl() {
      // TODO implement using webUrl from the API
      return `${gon.gitlab_url || ''}/admin/runners/${this.runnerNumericalId}`;
    },
    description() {
      return this.runner.description;
    },
    shortSha() {
      return this.runner.shortSha;
    },
  },
};
</script>

<template>
  <div>
    <gl-link :href="runnerUrl"> #{{ runnerNumericalId }} ({{ shortSha }})</gl-link>
    <tooltip-on-truncate class="gl-display-block" :title="description" truncate-target="child">
      <div class="gl-text-truncate">
        {{ description }}
      </div>
    </tooltip-on-truncate>
  </div>
</template>
