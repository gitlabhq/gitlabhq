<script>
import { GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    token: {
      default: null,
    },
    revokePath: {
      default: '',
    },
  },
  computed: {
    modalId() {
      return `revoke-modal-${this.token.id}`;
    },
  },
  methods: {
    cancelHandler() {
      this.$refs.modal.hide();
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-modal="modalId"
      category="secondary"
      variant="danger"
      size="small"
      data-testid="revoke-button"
      >{{ s__('DeployTokens|Revoke') }}</gl-button
    >
    <gl-modal ref="modal" :modal-id="modalId">
      <template #modal-title>
        <gl-sprintf :message="s__('DeployTokens|Revoke %{tokenName}?')">
          <template #tokenName
            ><b>{{ token.name }}</b></template
          >
        </gl-sprintf>
      </template>
      <gl-sprintf :message="s__('DeployTokens|You are about to revoke %{tokenName}.')">
        <template #tokenName>
          <b>{{ token.name }}</b>
        </template>
      </gl-sprintf>
      {{ s__('DeployTokens|This action cannot be undone.') }}
      <template #modal-footer>
        <gl-button category="secondary" @click="cancelHandler">{{ __('Cancel') }}</gl-button>
        <gl-button
          category="primary"
          variant="danger"
          :href="revokePath"
          data-method="put"
          class="text-truncate"
          data-testid="primary-revoke-btn"
        >
          <gl-sprintf :message="s__('DeployTokens|Revoke %{name}')">
            <template #name>{{ token.name }}</template>
          </gl-sprintf>
        </gl-button>
      </template>
    </gl-modal>
  </div>
</template>
