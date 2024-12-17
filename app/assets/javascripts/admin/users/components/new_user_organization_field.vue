<script>
import { GlAvatarLabeled } from '@gitlab/ui';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { s__ } from '~/locale';
import organizationsQuery from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import OrganizationRoleField from './organization_role_field.vue';

export default {
  name: 'NewUserOrganizationField',
  AVATAR_SHAPE_OPTION_RECT,
  organizationsQuery,
  organizationInputId: 'user_organization_id',
  organizationUserInputId: 'user_organization_users_id',
  organizationUserInputName: 'user[organization_users_attributes][][id]',
  i18n: {
    organizationSelectLabel: s__('Organization|Select an organization'),
  },
  components: { GlAvatarLabeled, OrganizationSelect, OrganizationRoleField },
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
    organizationRoleInputName: {
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
    <div v-else>
      <gl-avatar-labeled
        class="gl-mb-5"
        :entity-id="initialOrganization.id"
        :entity-name="initialOrganization.name"
        :label="initialOrganization.name"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :size="48"
        :src="initialOrganization.avatarUrl"
      />
      <input
        :id="$options.organizationInputId"
        :name="organizationInputName"
        :value="initialOrganization.id"
        type="hidden"
      />
    </div>
    <organization-role-field
      :initial-access-level="organizationUser.accessLevel"
      :input-name="organizationRoleInputName"
    />
  </div>
</template>
