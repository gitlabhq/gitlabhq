<script>
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { produce } from 'immer';
import { __, s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import createContact from './queries/create_contact.mutation.graphql';
import getGroupContactsQuery from './queries/get_group_contacts.query.graphql';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  inject: ['groupFullPath', 'groupId'],
  data() {
    return {
      firstName: '',
      lastName: '',
      phone: '',
      email: '',
      description: '',
      submitting: false,
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
          if (data.customerRelationsContactCreate.errors.length === 0) this.close();

          this.submitting = false;
        })
        .catch(() => {
          this.error();
          this.submitting = false;
        });
    },
    close() {
      this.$emit('close');
    },
    error(errors = null) {
      this.$emit('error', errors);
    },
    updateCache(store, { data: { customerRelationsContactCreate } }) {
      if (customerRelationsContactCreate.errors.length > 0) {
        this.error(customerRelationsContactCreate.errors);
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
  },
  i18n: {
    buttonLabel: s__('Crm|Create new contact'),
    cancel: __('Cancel'),
    firstName: s__('Crm|First name'),
    lastName: s__('Crm|Last name'),
    email: s__('Crm|Email'),
    phone: s__('Crm|Phone number (optional)'),
    description: s__('Crm|Description (optional)'),
  },
};
</script>

<template>
  <div class="col-md-4">
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
      <div class="form-actions">
        <gl-button
          variant="confirm"
          :disabled="invalid"
          :loading="submitting"
          data-testid="create-new-contact-button"
          type="submit"
          >{{ $options.i18n.buttonLabel }}</gl-button
        >
        <gl-button data-testid="cancel-button" @click="close">
          {{ $options.i18n.cancel }}
        </gl-button>
      </div>
    </form>
    <div class="gl-pb-5"></div>
  </div>
</template>
