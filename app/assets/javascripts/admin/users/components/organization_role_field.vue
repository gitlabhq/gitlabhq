<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';
import { __ } from '~/locale';

export default {
  name: 'OrganizationRoleField',
  i18n: {
    label: __('Role'),
  },
  inputId: 'user_organization_access_level',
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
  props: {
    initialAccessLevel: {
      type: String,
      required: false,
      default: ACCESS_LEVEL_DEFAULT,
    },
    inputName: {
      type: String,
      required: false,
      default: 'user[organization_access_level]',
    },
  },
  data() {
    return {
      accessLevel: this.initialAccessLevel,
    };
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.label">
    <gl-collapsible-listbox
      v-model="accessLevel"
      block
      toggle-class="gl-form-input-xl"
      :items="$options.roleListboxItems"
    />
    <input :id="$options.inputId" :name="inputName" :value="accessLevel" type="hidden" />
  </gl-form-group>
</template>
