<script>
import { GlButton, GlTooltipDirective as GlTooltip, GlLink } from '@gitlab/ui';
import { convertCandidateFromGraphql } from '~/ml/model_registry/utils';
import * as i18n from '../translations';
import CandidateDetail from './candidate_detail.vue';

export default {
  name: 'ModelVersionPerformance',
  components: {
    CandidateDetail,
    GlButton,
    GlLink,
  },
  directives: {
    GlTooltip,
  },
  props: {
    modelVersion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    candidate() {
      return convertCandidateFromGraphql(this.modelVersion.candidate);
    },
  },
  methods: {
    copyMlflowId() {
      navigator.clipboard.writeText(this.candidate.info.eid);
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <div class="gl-mt-5 gl-pb-5">
      <span class="gl-font-bold">{{ $options.i18n.MLFLOW_ID_LABEL }}:</span>
      <p class="gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap">
        <gl-link :href="candidate.info.path">
          {{ candidate.info.eid }}
        </gl-link>
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          :aria-label="__('Copy MLflow run ID')"
          :title="__('Copy MLflow run ID')"
          icon="copy-to-clipboard"
          @click="copyMlflowId"
        />
      </p>
      <candidate-detail :candidate="candidate" />
    </div>
  </div>
</template>
