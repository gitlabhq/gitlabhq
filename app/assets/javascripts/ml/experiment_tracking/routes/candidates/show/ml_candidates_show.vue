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
  computed: {
    info() {
      return Object.freeze(this.candidate.info);
    },
  },
};
</script>

<template>
  <div>
    <candidate-header :info="info" />
    <candidate-detail :candidate="candidate" />
  </div>
</template>
