<script>
import { GlFormGroup } from '@gitlab/ui';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';

export default {
  name: 'TransferProjectForm',
  components: {
    GlFormGroup,
    NamespaceSelect,
    ConfirmDanger,
  },
  props: {
    namespaces: {
      type: Object,
      required: true,
    },
    confirmationPhrase: {
      type: String,
      required: true,
    },
    confirmButtonText: {
      type: String,
      required: true,
    },
  },
  data() {
    return { selectedNamespace: null };
  },
  computed: {
    hasSelectedNamespace() {
      return Boolean(this.selectedNamespace?.id);
    },
  },
  methods: {
    handleSelect(selectedNamespace) {
      this.selectedNamespace = selectedNamespace;
      this.$emit('selectNamespace', selectedNamespace.id);
    },
  },
};
</script>
<template>
  <div>
    <gl-form-group>
      <namespace-select
        data-testid="transfer-project-namespace"
        :full-width="true"
        :data="namespaces"
        :selected-namespace="selectedNamespace"
        @select="handleSelect"
      />
    </gl-form-group>
    <confirm-danger
      button-class="qa-transfer-button"
      :disabled="!hasSelectedNamespace"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
