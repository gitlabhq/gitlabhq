<script>
import { GlModal, GlModalDirective, GlDeprecatedButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlModal,
    GlDeprecatedButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    deleteMetricUrl: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    },
  },
  descriptionText: s__(
    `Metrics|You're about to permanently delete this metric. This cannot be undone.`,
  ),
  modalId: 'delete-custom-metric-modal',
};
</script>
<template>
  <div class="d-inline-block float-right mr-3">
    <gl-deprecated-button v-gl-modal="$options.modalId" variant="danger">
      {{ __('Delete') }}
    </gl-deprecated-button>
    <gl-modal
      :title="s__('Metrics|Delete metric?')"
      :ok-title="s__('Metrics|Delete metric')"
      :modal-id="$options.modalId"
      ok-variant="danger"
      @ok="onSubmit"
    >
      {{ $options.descriptionText }}

      <form ref="form" :action="deleteMetricUrl" method="post">
        <input type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
