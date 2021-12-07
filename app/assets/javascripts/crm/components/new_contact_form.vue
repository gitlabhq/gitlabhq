<script>
import { GlAlert, GlButton, GlDrawer, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { produce } from 'immer';
import { __, s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import createContact from './queries/create_contact.mutation.graphql';
import getGroupContactsQuery from './queries/get_group_contacts.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlDrawer,
    GlFormGroup,
    GlFormInput,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    drawerOpen: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      firstName: '',
      lastName: '',
      phone: '',
      email: '',
      description: '',
      submitting: false,
      errorMessages: [],
    };
  },
  computed: {
    invalid() {
      return this.firstName === '' || this.lastName === '' || this.email === '';
    },
  },
  methods: {
    save() {
      this.submitting = true;
      return this.$apollo
        .mutate({
          mutation: createContact,
          variables: {
            input: {
              groupId: convertToGraphQLId(TYPE_GROUP, this.groupId),
              firstName: this.firstName,
              lastName: this.lastName,
              phone: this.phone,
              email: this.email,
              description: this.description,
            },
          },
          update: this.updateCache,
        })
        .then(({ data }) => {
          if (data.customerRelationsContactCreate.errors.length === 0) this.close(true);

          this.submitting = false;
        })
        .catch(() => {
          this.errorMessages = [__('Something went wrong. Please try again.')];
          this.submitting = false;
        });
    },
    close(success) {
      this.$emit('close', success);
    },
    updateCache(store, { data: { customerRelationsContactCreate } }) {
      if (customerRelationsContactCreate.errors.length > 0) {
        this.errorMessages = customerRelationsContactCreate.errors;
        return;
      }

      const variables = {
        groupFullPath: this.groupFullPath,
      };
      const sourceData = store.readQuery({
        query: getGroupContactsQuery,
        variables,
      });

      const data = produce(sourceData, (draftState) => {
        draftState.group.contacts.nodes = [
          ...sourceData.group.contacts.nodes,
          customerRelationsContactCreate.contact,
        ];
      });

      store.writeQuery({
        query: getGroupContactsQuery,
        variables,
        data,
      });
    },
    getDrawerHeaderHeight() {
      const wrapperEl = document.querySelector('.content-wrapper');

      if (wrapperEl) {
        return `${wrapperEl.offsetTop}px`;
      }

      return '';
    },
  },
  i18n: {
    buttonLabel: s__('Crm|Create new contact'),
    cancel: __('Cancel'),
    firstName: s__('Crm|First name'),
    lastName: s__('Crm|Last name'),
    email: s__('Crm|Email'),
    phone: s__('Crm|Phone number (optional)'),
    description: s__('Crm|Description (optional)'),
    title: s__('Crm|New Contact'),
  },
};
</script>

<template>
  <gl-drawer
    class="gl-drawer-responsive"
    :open="drawerOpen"
    :header-height="getDrawerHeaderHeight()"
    @close="close(false)"
  >
    <template #title>
      <h4>{{ $options.i18n.title }}</h4>
    </template>
    <gl-alert v-if="errorMessages.length" variant="danger" @dismiss="errorMessages = []">
      <ul class="gl-mb-0! gl-ml-5">
        <li v-for="error in errorMessages" :key="error">
          {{ error }}
        </li>
      </ul>
    </gl-alert>
    <form @submit.prevent="save">
      <gl-form-group :label="$options.i18n.firstName" label-for="contact-first-name">
        <gl-form-input id="contact-first-name" v-model="firstName" />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.lastName" label-for="contact-last-name">
        <gl-form-input id="contact-last-name" v-model="lastName" />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.email" label-for="contact-email">
        <gl-form-input id="contact-email" v-model="email" />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.phone" label-for="contact-phone">
        <gl-form-input id="contact-phone" v-model="phone" />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.description" label-for="contact-description">
        <gl-form-input id="contact-description" v-model="description" />
      </gl-form-group>
      <span class="gl-float-right">
        <gl-button data-testid="cancel-button" @click="close(false)">
          {{ $options.i18n.cancel }}
        </gl-button>
        <gl-button
          variant="confirm"
          :disabled="invalid"
          :loading="submitting"
          data-testid="create-new-contact-button"
          type="submit"
          >{{ $options.i18n.buttonLabel }}</gl-button
        >
      </span>
    </form>
  </gl-drawer>
</template>
