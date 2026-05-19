<script>
import { mapState } from 'pinia';
import { GlModal, GlButton, GlForm, GlFormFields, GlAlert } from '@gitlab/ui';
import { s__, __ } from '~/locale';

import { useServiceAccounts } from '../stores/service_accounts';

export default {
  name: 'CreateEditServiceAccountModal',
  components: {
    GlModal,
    GlButton,
    GlForm,
    GlFormFields,
    GlAlert,
  },
  props: {
    serviceAccount: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['submit', 'cancel'],
  data() {
    const serviceAccount = { ...this.serviceAccount };

    // If server generated placeholder email ignore it - magic string :-(
    if (serviceAccount?.email?.includes('@noreply.')) {
      serviceAccount.email = null;
    }

    return {
      values: serviceAccount,
    };
  },
  computed: {
    ...mapState(useServiceAccounts, ['busy', 'createEditType', 'createEditError']),
    modalTitle() {
      return this.$options.i18n.title[this.createEditType];
    },
    modalButton() {
      return this.$options.i18n.primaryButtonLabel[this.createEditType];
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit', this.values);
    },
    onCancel() {
      this.$emit('cancel');
    },
  },
  fields: {
    name: {
      label: __('Name'),
    },
    username: {
      label: __('Username'),
      groupAttrs: {
        optional: true,
        'optional-text': __('(optional)'),
      },
    },
    email: {
      label: __('Email'),
      groupAttrs: {
        optional: true,
        'optional-text': __('(optional)'),
      },
    },
  },
  i18n: {
    title: {
      create: s__('AdminUsers|Create service account'),
      edit: s__('AdminUsers|Edit service account'),
    },
    primaryButtonLabel: {
      create: s__('AdminUsers|Create'),
      edit: s__('AdminUsers|Edit'),
    },
  },
};
</script>
<template>
  <gl-modal
    visible
    modal-id="create-edit-service-account-modal"
    :title="modalTitle"
    hide-footer
    @close="onCancel"
    @hide="onCancel"
  >
    <gl-alert v-if="createEditError" :dismissible="false" variant="danger">
      {{ createEditError }}
    </gl-alert>

    <gl-form id="create-edit-service-account" @submit.prevent>
      <gl-form-fields
        v-model="values"
        form-id="create-edit-service-account"
        :fields="$options.fields"
        @submit="onSubmit"
      >
        <template #group(username)-description>
          {{ s__('AdminUsers|Unique username that can be called for usage across GitLab') }}
        </template>
      </gl-form-fields>

      <div class="gl-flex gl-flex-wrap gl-justify-end gl-gap-3">
        <gl-button data-testid="cancel-button" @click="onCancel">{{ __('Cancel') }}</gl-button>
        <gl-button variant="confirm" type="submit" class="js-no-auto-disable" :loading="busy">
          {{ modalButton }}
        </gl-button>
      </div>
    </gl-form>
  </gl-modal>
</template>
