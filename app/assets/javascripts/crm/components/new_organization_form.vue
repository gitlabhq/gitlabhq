<script>
import { GlAlert, GlButton, GlDrawer, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { produce } from 'immer';
import { __, s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import createOrganization from './queries/create_organization.mutation.graphql';
import getGroupOrganizationsQuery from './queries/get_group_organizations.query.graphql';

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
      name: '',
      defaultRate: null,
      description: '',
      submitting: false,
      errorMessages: [],
    };
  },
  computed: {
    invalid() {
      return this.name.trim() === '';
    },
  },
  methods: {
    save() {
      this.submitting = true;
      return this.$apollo
        .mutate({
          mutation: createOrganization,
          variables: {
            input: {
              groupId: convertToGraphQLId(TYPE_GROUP, this.groupId),
              name: this.name,
              defaultRate: this.defaultRate ? parseFloat(this.defaultRate) : null,
              description: this.description,
            },
          },
          update: this.updateCache,
        })
        .then(({ data }) => {
          if (data.customerRelationsOrganizationCreate.errors.length === 0) this.close(true);

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
    updateCache(store, { data: { customerRelationsOrganizationCreate } }) {
      if (customerRelationsOrganizationCreate.errors.length > 0) {
        this.errorMessages = customerRelationsOrganizationCreate.errors;
        return;
      }

      const variables = {
        groupFullPath: this.groupFullPath,
      };
      const sourceData = store.readQuery({
        query: getGroupOrganizationsQuery,
        variables,
      });

      const data = produce(sourceData, (draftState) => {
        draftState.group.organizations.nodes = [
          ...sourceData.group.organizations.nodes,
          customerRelationsOrganizationCreate.organization,
        ];
      });

      store.writeQuery({
        query: getGroupOrganizationsQuery,
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
    buttonLabel: s__('Crm|Create organization'),
    cancel: __('Cancel'),
    name: __('Name'),
    defaultRate: s__('Crm|Default rate (optional)'),
    description: __('Description (optional)'),
    title: s__('Crm|New Organization'),
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
      <gl-form-group :label="$options.i18n.name" label-for="organization-name">
        <gl-form-input id="organization-name" v-model="name" />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.defaultRate" label-for="organization-default-rate">
        <gl-form-input
          id="organization-default-rate"
          v-model="defaultRate"
          type="number"
          step="0.01"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.description" label-for="organization-description">
        <gl-form-input id="organization-description" v-model="description" />
      </gl-form-group>
      <span class="gl-float-right">
        <gl-button data-testid="cancel-button" @click="close(false)">
          {{ $options.i18n.cancel }}
        </gl-button>
        <gl-button
          variant="confirm"
          :disabled="invalid"
          :loading="submitting"
          data-testid="create-new-organization-button"
          type="submit"
          >{{ $options.i18n.buttonLabel }}</gl-button
        >
      </span>
    </form>
  </gl-drawer>
</template>
