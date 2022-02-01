<script>
import { GlFormGroup } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';

export const i18n = {
  confirmationMessage: __(
    'You are going to transfer %{group_name} to another namespace. Are you ABSOLUTELY sure?',
  ),
  emptyNamespaceTitle: __('No parent group'),
  dropdownTitle: s__('GroupSettings|Select parent group'),
};

export default {
  name: 'TransferGroupForm',
  components: {
    ConfirmDanger,
    GlFormGroup,
    NamespaceSelect,
  },
  props: {
    parentGroups: {
      type: Object,
      required: true,
    },
    isPaidGroup: {
      type: Boolean,
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
    return {
      selectedId: null,
    };
  },
  computed: {
    selectedNamespaceId() {
      return this.selectedId;
    },
    disableSubmitButton() {
      return this.isPaidGroup || !this.selectedId;
    },
  },
  methods: {
    handleSelected({ id }) {
      this.selectedId = id;
    },
  },
  i18n,
};
</script>
<template>
  <div>
    <gl-form-group v-if="!isPaidGroup">
      <namespace-select
        :default-text="$options.i18n.dropdownTitle"
        :data="parentGroups"
        :empty-namespace-title="$options.i18n.emptyNamespaceTitle"
        :include-headers="false"
        include-empty-namespace
        @select="handleSelected"
      />
      <input type="hidden" name="new_parent_group_id" :value="selectedId" />
    </gl-form-group>
    <confirm-danger
      button-class="qa-transfer-button"
      :disabled="disableSubmitButton"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
