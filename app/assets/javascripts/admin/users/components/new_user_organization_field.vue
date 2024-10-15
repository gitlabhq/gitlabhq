<script>
import { GlAvatarLabeled } from '@gitlab/ui';
import OrganizationSelect from '~/vue_shared/components/entity_select/organization_select.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { s__ } from '~/locale';
import OrganizationRoleField from './organization_role_field.vue';

export default {
  AVATAR_SHAPE_OPTION_RECT,
  inputName: 'user[organization_id]',
  inputId: 'user_organization_id',
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
  },
  computed: {
    initialSelection() {
      return {
        text: this.initialOrganization.name,
        value: this.initialOrganization.id,
      };
    },
  },
};
</script>

<template>
  <div>
    <organization-select
      v-if="hasMultipleOrganizations"
      block
      :initial-selection="initialSelection"
      :input-name="$options.inputName"
      :input-id="$options.inputId"
      toggle-class="gl-form-input-xl"
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
    </div>
    <organization-role-field />
  </div>
</template>
