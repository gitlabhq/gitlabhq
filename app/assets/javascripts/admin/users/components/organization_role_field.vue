<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';
import { __ } from '~/locale';

export default {
  name: 'OrganizationRoleField',
  i18n: {
    label: __('Role'),
  },
  inputName: 'user[organization_access_level]',
  inputId: 'user[organization_access_level]',
  roleListboxItems: [
    {
      text: __('User'),
      value: ACCESS_LEVEL_DEFAULT,
    },
    {
      text: __('Owner'),
      value: ACCESS_LEVEL_OWNER,
    },
  ],
  components: { GlFormGroup, GlCollapsibleListbox },
  data() {
    return {
      roleAccessLevel: ACCESS_LEVEL_DEFAULT,
    };
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.label">
    <gl-collapsible-listbox
      v-model="roleAccessLevel"
      block
      toggle-class="gl-form-input-xl"
      :items="$options.roleListboxItems"
    />
    <input
      :id="$options.inputId"
      :name="$options.inputName"
      :value="roleAccessLevel"
      type="hidden"
    />
  </gl-form-group>
</template>
