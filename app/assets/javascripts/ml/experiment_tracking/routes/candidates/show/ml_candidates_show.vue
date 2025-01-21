<script>
import CandidateHeader from './candidate_header.vue';
import CandidateDetail from './candidate_detail.vue';

export default {
  name: 'MlCandidatesShow',
  components: {
    CandidateHeader,
    CandidateDetail,
  },
  props: {
    candidate: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <candidate-header :candidate="candidate" />
    <candidate-detail :candidate="candidate" />
  </div>
</template>
