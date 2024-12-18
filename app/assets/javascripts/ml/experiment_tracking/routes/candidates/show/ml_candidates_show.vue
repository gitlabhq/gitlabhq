<script>
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import CandidateDetail from '~/ml/model_registry/components/candidate_detail.vue';
import { s__ } from '~/locale';

export default {
  name: 'MlCandidatesShow',
  components: {
    ModelExperimentsHeader,
    DeleteButton,
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
  i18n: {
    TITLE_LABEL: s__('MlExperimentTracking|Model candidate details'),
    DELETE_CANDIDATE_CONFIRMATION_MESSAGE: s__(
      'MlExperimentTracking|Deleting this candidate will delete the associated parameters, metrics, and metadata.',
    ),
    DELETE_CANDIDATE_PRIMARY_ACTION_LABEL: s__('MlExperimentTracking|Delete candidate'),
    DELETE_CANDIDATE_MODAL_TITLE: s__('MlExperimentTracking|Delete candidate?'),
  },
};
</script>

<template>
  <div>
    <model-experiments-header :page-title="$options.i18n.TITLE_LABEL" hide-mlflow-usage>
      <delete-button
        :delete-path="info.path"
        :delete-confirmation-text="$options.i18n.DELETE_CANDIDATE_CONFIRMATION_MESSAGE"
        :action-primary-text="$options.i18n.DELETE_CANDIDATE_PRIMARY_ACTION_LABEL"
        :modal-title="$options.i18n.DELETE_CANDIDATE_MODAL_TITLE"
      />
    </model-experiments-header>

    <candidate-detail :candidate="candidate" />
  </div>
</template>
