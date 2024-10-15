<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { ACCESS_LEVEL_GUEST_INTEGER, ACCESS_LEVEL_OWNER_INTEGER } from '~/access_level/constants';
import { __ } from '~/locale';

export default {
  i18n: {
    label: __('Role'),
  },
  inputName: 'user[organization_access_level]',
  inputId: 'user_access_level',
  roleListboxItems: [
    {
      text: __('User'),
      value: ACCESS_LEVEL_GUEST_INTEGER,
    },
    {
      text: __('Owner'),
      value: ACCESS_LEVEL_OWNER_INTEGER,
    },
  ],
  components: { GlFormGroup, GlCollapsibleListbox },
  data() {
    return {
      roleAccessLevel: ACCESS_LEVEL_GUEST_INTEGER,
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
      :id="$options.inputName"
      :name="$options.inputId"
      :value="roleAccessLevel"
      type="hidden"
    />
  </gl-form-group>
</template>
