<script>
import { GlAlert, GlButton, GlDrawer, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { produce } from 'immer';
import { __, s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import createContactMutation from './queries/create_contact.mutation.graphql';
import updateContactMutation from './queries/update_contact.mutation.graphql';
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
    contact: {
      type: Object,
      required: false,
      default: () => {},
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
      const { firstName, lastName, email } = this;

      return firstName.trim() === '' || lastName.trim() === '' || email.trim() === '';
    },
    editMode() {
      return Boolean(this.contact);
    },
    title() {
      return this.editMode ? this.$options.i18n.editTitle : this.$options.i18n.newTitle;
    },
    buttonLabel() {
      return this.editMode
        ? this.$options.i18n.editButtonLabel
        : this.$options.i18n.createButtonLabel;
    },
    mutation() {
      return this.editMode ? updateContactMutation : createContactMutation;
    },
    variables() {
      const { contact, firstName, lastName, phone, email, description, editMode, groupId } = this;

      const variables = {
        input: {
          firstName,
          lastName,
          phone,
          email,
          description,
        },
      };

      if (editMode) {
        variables.input.id = contact.id;
      } else {
        variables.input.groupId = convertToGraphQLId(TYPE_GROUP, groupId);
      }

      return variables;
    },
  },
  mounted() {
    if (this.editMode) {
      const { contact } = this;

      this.firstName = contact.firstName || '';
      this.lastName = contact.lastName || '';
      this.phone = contact.phone || '';
      this.email = contact.email || '';
      this.description = contact.description || '';
    }
  },
  methods: {
    save() {
      const { mutation, variables, updateCache, close } = this;

      this.submitting = true;

      return this.$apollo
        .mutate({
          mutation,
          variables,
          update: updateCache,
        })
        .then(({ data }) => {
          if (
            data.customerRelationsContactCreate?.errors.length === 0 ||
            data.customerRelationsContactUpdate?.errors.length === 0
          ) {
            close(true);
          }

          this.submitting = false;
        })
        .catch(() => {
          this.errorMessages = [this.$options.i18n.somethingWentWrong];
          this.submitting = false;
        });
    },
    close(success) {
      this.$emit('close', success);
    },
    updateCache(store, { data }) {
      const mutationData =
        data.customerRelationsContactCreate || data.customerRelationsContactUpdate;

      if (mutationData?.errors.length > 0) {
        this.errorMessages = mutationData.errors;
        return;
      }

      const queryArgs = {
        query: getGroupContactsQuery,
        variables: { groupFullPath: this.groupFullPath },
      };

      const sourceData = store.readQuery(queryArgs);

      queryArgs.data = produce(sourceData, (draftState) => {
        draftState.group.contacts.nodes = [
          ...sourceData.group.contacts.nodes.filter(({ id }) => id !== this.contact?.id),
          mutationData.contact,
        ];
      });

      store.writeQuery(queryArgs);
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
    createButtonLabel: s__('Crm|Create new contact'),
    editButtonLabel: __('Save changes'),
    cancel: __('Cancel'),
    firstName: s__('Crm|First name'),
    lastName: s__('Crm|Last name'),
    email: s__('Crm|Email'),
    phone: s__('Crm|Phone number (optional)'),
    description: s__('Crm|Description (optional)'),
    newTitle: s__('Crm|New contact'),
    editTitle: s__('Crm|Edit contact'),
    somethingWentWrong: __('Something went wrong. Please try again.'),
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
      <h3>{{ title }}</h3>
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
          data-testid="save-contact-button"
          type="submit"
          >{{ buttonLabel }}</gl-button
        >
      </span>
    </form>
  </gl-drawer>
</template>
