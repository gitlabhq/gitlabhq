<script>
import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { projectCommitsPath } from '~/lib/utils/path_helpers/repository';
import { encodeUrlHash } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

const SYMBOLIC_REF_PREFIX = /^refs\/(heads|tags)\//;

/**
 * Pipeline Stop Modal.
 *
 * Renders the modal used to confirm cancelling a pipeline.
 */
export default {
  name: 'PipelineStopModal',
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
  emits: ['close-modal', 'submit'],
  computed: {
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline.id);
    },
    refName() {
      const { ref, refPath } = this.pipeline;

      if (refPath) return refPath.replace(SYMBOLIC_REF_PREFIX, '');

      return ref;
    },
    refHref() {
      const { refUrl, project } = this.pipeline;

      if (refUrl) return refUrl;
      if (!this.refName || !project?.fullPath) return null;

      return encodeUrlHash(projectCommitsPath(project.fullPath, this.refName));
    },
    modalTitle() {
      return sprintf(
        s__('Pipeline|Stop pipeline #%{pipelineId}?'),
        {
          pipelineId: `${this.pipelineId}`,
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
          <strong>{{ pipelineId }}</strong>
        </template>
      </gl-sprintf>
    </p>

    <p>
      <ci-icon
        v-if="pipeline.detailedStatus"
        :status="pipeline.detailedStatus"
        class="vertical-align-middle"
      />

      <span class="gl-font-bold">{{ __('Pipeline') }}</span>

      <a :href="pipeline.path" data-testid="pipeline-path">#{{ pipelineId }}</a>
      <template v-if="refHref">
        {{ __('from') }}
        <a :href="refHref" class="ref-name" data-testid="pipeline-ref">{{ refName }}</a>
      </template>
    </p>

    <template v-if="pipeline.commit">
      <p>
        <span class="gl-font-bold">{{ __('Commit') }}</span>

        <gl-link :href="pipeline.commit.webPath" class="commit-sha" data-testid="commit-sha">
          {{ pipeline.commit.shortId }}
        </gl-link>
      </p>
      <p>{{ pipeline.commit.title }}</p>
    </template>
  </gl-modal>
</template>
