<script>
import { mapState } from 'pinia';
import { GlModal, GlButton, GlForm, GlFormFields, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

import { useServiceAccounts } from '../stores/service_accounts';

export default {
  name: 'DeleteServiceAccountModal',
  components: {
    GlModal,
    GlButton,
    GlForm,
    GlFormFields,
    GlSprintf,
  },
  props: {
    deleteType: {
      type: String,
      required: true,
      validator: (value) => ['soft', 'hard'].includes(value),
    },
    name: {
      type: String,
      required: true,
    },
  },
  emits: ['submit', 'cancel'],
  data() {
    return {
      values: {},
      fields: {
        name: {
          validators: [(val) => (val !== this.name ? s__('AdminUsers|Name not matching') : '')],
          inputAttrs: {
            autofocus: true,
            autocomplete: 'off',
          },
        },
      },
    };
  },
  computed: {
    ...mapState(useServiceAccounts, ['busy']),
    modalTitle() {
      return sprintf(this.$options.i18n.title[this.deleteType], { name: this.name }, false);
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit');
    },
    onCancel() {
      this.$emit('cancel');
    },
  },
  i18n: {
    title: {
      soft: s__("AdminUsers|Delete User '%{name}'?"),
      hard: s__("AdminUsers|Delete User '%{name}' and contributions?"),
    },
    primaryButtonLabel: {
      soft: s__('AdminUsers|Delete user'),
      hard: s__('AdminUsers|Delete user and contributions'),
    },
    messageBody: {
      soft: s__(`AdminUsers|You are about to permanently delete the user %{name}. Issues, merge requests,
                              and groups linked to them will be transferred to a system-wide "Ghost-user". Once you %{strongStart}Delete user%{strongEnd},
                              it cannot be undone or recovered.`),
      hard: s__(`AdminUsers|You are about to permanently delete the user %{name}. This will delete all issues,
                            merge requests, groups, and projects linked to them. After you %{strongStart}Delete user%{strongEnd},
                            you cannot undo this action or recover the data.`),
    },
  },
};
</script>
<template>
  <gl-modal
    visible
    modal-id="delete-user-modal"
    :title="modalTitle"
    hide-footer
    @close="onCancel"
    @hide="onCancel"
  >
    <p>
      <gl-sprintf :message="$options.i18n.messageBody[deleteType]">
        <template #name>
          <strong data-testid="message-name">{{ name }}</strong>
        </template>
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </p>

    <gl-form id="delete-service-account" @submit.prevent>
      <gl-form-fields
        v-model="values"
        form-id="delete-service-account"
        :fields="fields"
        @submit="onSubmit"
      >
        <template #group(name)-label>
          <gl-sprintf :message="s__('AdminUsers|To confirm, type %{name}')">
            <template #name>
              <code data-testid="confirm-name">{{ name }}</code>
            </template>
          </gl-sprintf>
        </template>
      </gl-form-fields>

      <div class="gl-flex gl-flex-wrap gl-justify-end gl-gap-3">
        <gl-button data-testid="cancel-button" @click="onCancel">{{ __('Cancel') }}</gl-button>
        <gl-button variant="danger" type="submit" class="js-no-auto-disable" :loading="busy">
          {{ $options.i18n.primaryButtonLabel[deleteType] }}
        </gl-button>
      </div>
    </gl-form>
  </gl-modal>
</template>
