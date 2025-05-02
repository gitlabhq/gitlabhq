<script>
import { convertCandidateFromGraphql } from '~/ml/model_registry/utils';
import CandidateDetail from './candidate_detail.vue';

export default {
  name: 'ModelVersionPerformance',
  components: {
    CandidateDetail,
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
};
</script>

<template>
  <candidate-detail :candidate="candidate" />
</template>
