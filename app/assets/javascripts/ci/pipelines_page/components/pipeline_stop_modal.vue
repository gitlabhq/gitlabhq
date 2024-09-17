<script>
import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { __, s__, sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

/**
 * Pipeline Stop Modal.
 *
 * Renders the modal used to confirm cancelling a pipeline.
 */
export default {
  components: {
    GlModal,
    GlLink,
    GlSprintf,
    CiIcon,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
      deep: true,
    },
    showConfirmationModal: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    hasRef() {
      return !isEmpty(this.pipeline.ref);
    },
    modalTitle() {
      return sprintf(
        s__('Pipeline|Stop pipeline #%{pipelineId}?'),
        {
          pipelineId: `${this.pipeline.id}`,
        },
        false,
      );
    },
    modalText() {
      return s__(`Pipeline|You're about to stop pipeline #%{pipelineId}.`);
    },
    primaryProps() {
      return {
        text: s__('Pipeline|Stop pipeline'),
        attributes: { variant: 'danger' },
      };
    },
    showModal: {
      get() {
        return this.showConfirmationModal;
      },
      set() {
        this.$emit('close-modal');
      },
    },
  },
  methods: {
    emitSubmit(event) {
      this.$emit('submit', event);
    },
  },
  cancelProps: { text: __('Cancel') },
};
</script>
<template>
  <gl-modal
    v-model="showModal"
    modal-id="confirmation-modal"
    :title="modalTitle"
    :action-primary="primaryProps"
    :action-cancel="$options.cancelProps"
    data-testid="pipeline-stop-modal"
    @primary="emitSubmit($event)"
  >
    <p>
      <gl-sprintf :message="modalText">
        <template #pipelineId>
          <strong>{{ pipeline.id }}</strong>
        </template>
      </gl-sprintf>
    </p>

    <p>
      <ci-icon
        v-if="pipeline.details"
        :status="pipeline.details.status"
        class="vertical-align-middle"
      />

      <span class="font-weight-bold">{{ __('Pipeline') }}</span>

      <a :href="pipeline.path" class="js-pipeline-path link-commit">#{{ pipeline.id }}</a>
      <template v-if="hasRef">
        {{ __('from') }}
        <a :href="pipeline.ref.path" class="link-commit ref-name">{{ pipeline.ref.name }}</a>
      </template>
    </p>

    <template v-if="pipeline.commit">
      <p>
        <span class="font-weight-bold">{{ __('Commit') }}</span>

        <gl-link :href="pipeline.commit.commit_path" class="js-commit-sha commit-sha link-commit">
          {{ pipeline.commit.short_id }}
        </gl-link>
      </p>
      <p>{{ pipeline.commit.title }}</p>
    </template>
  </gl-modal>
</template>
