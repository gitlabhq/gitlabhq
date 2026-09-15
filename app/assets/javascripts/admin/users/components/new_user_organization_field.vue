<script>
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import { s__ } from '~/locale';
import organizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import OrganizationUserTypeField from './organization_user_type_field.vue';

export default {
  name: 'NewUserOrganizationField',
  organizationsQuery,
  organizationInputId: 'user_organization_id',
  organizationUserInputId: 'user_organization_users_id',
  organizationUserInputName: 'user[organization_users_attributes][][id]',
  i18n: {
    organizationSelectLabel: s__('Organization|Select an organization'),
  },
  components: { OrganizationSelect, OrganizationUserTypeField },
  props: {
    hasMultipleOrganizations: {
      type: Boolean,
      required: true,
    },
    initialOrganization: {
      type: Object,
      required: true,
    },
    organizationUser: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
    organizationInputName: {
      type: String,
      required: false,
      default: 'user[organization_id]',
    },
    organizationUserTypeInputName: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    initialSelection() {
      return {
        text: this.initialOrganization.name,
        value: this.initialOrganization.id,
      };
    },
    isOrganizationUserDefined() {
      return Object.keys(this.organizationUser).length;
    },
  },
};
</script>

<template>
  <div>
    <input
      v-if="isOrganizationUserDefined"
      :id="$options.organizationUserInputId"
      :name="$options.organizationUserInputName"
      :value="organizationUser.id"
      type="hidden"
    />
    <organization-select
      v-if="hasMultipleOrganizations"
      :query="$options.organizationsQuery"
      query-path="organizations"
      block
      :initial-selection="initialSelection"
      :input-name="organizationInputName"
      :input-id="$options.organizationInputId"
      toggle-class="gl-form-input-xl"
      :searchable="false"
    >
      <template #label>
        <span class="gl-sr-only">{{ $options.i18n.organizationSelectLabel }}</span>
      </template>
    </organization-select>
    <input
      v-else
      :id="$options.organizationInputId"
      :name="organizationInputName"
      :value="initialOrganization.id"
      type="hidden"
    />
    <organization-user-type-field
      :initial-access-level="organizationUser.accessLevel"
      :input-name="organizationUserTypeInputName"
    />
  </div>
</template>
