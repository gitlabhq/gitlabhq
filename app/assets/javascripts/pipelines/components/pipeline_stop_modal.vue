<script>
import _ from 'underscore';
import { GlLink } from '@gitlab/ui';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import { s__, sprintf } from '~/locale';

/**
 * Pipeline Stop Modal.
 *
 * Renders the modal used to confirm stopping a pipeline.
 */
export default {
  components: {
    GlModal: DeprecatedModal2,
    GlLink,
    ClipboardButton,
    CiIcon,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
      deep: true,
    },
  },
  computed: {
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
      return sprintf(
        s__(`Pipeline|You’re about to stop pipeline %{pipelineId}.`),
        {
          pipelineId: `<strong>#${this.pipeline.id}</strong>`,
        },
        false,
      );
    },
    hasRef() {
      return !_.isEmpty(this.pipeline.ref);
    },
  },
  methods: {
    emitSubmit(event) {
      this.$emit('submit', event);
    },
  },
};
</script>
<template>
  <gl-modal
    id="confirmation-modal"
    :header-title-text="modalTitle"
    :footer-primary-button-text="s__('Pipeline|Stop pipeline')"
    footer-primary-button-variant="danger"
    @submit="emitSubmit($event)"
  >
    <p v-html="modalText"></p>

    <p v-if="pipeline">
      <ci-icon
        v-if="pipeline.details"
        :status="pipeline.details.status"
        class="vertical-align-middle"
      />

      <span class="font-weight-bold">{{ __('Pipeline') }}</span>

      <a :href="pipeline.path" class="js-pipeline-path link-commit qa-pipeline-path"
        >#{{ pipeline.id }}</a
      >
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
