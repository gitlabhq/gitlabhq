<script>
import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { s__ } from '~/locale';

export const USER_TYPE_REGULAR = {
  value: 'regular',
  text: s__('AdminUsers|Regular'),
  description: s__('AdminUsers|Access to their groups and projects.'),
};
export const USER_TYPE_AUDITOR = {
  value: 'auditor',
  text: s__('AdminUsers|Auditor'),
  description: s__(
    'AdminUsers|Read-only access to all groups and projects. No access to the Admin area by default.',
  ),
};
// description is set dynamically based on isCurrentUser prop.
export const USER_TYPE_ADMIN = { value: 'admin', text: s__('AdminUsers|Administrator') };

// This component is rendered inside a HTML form, so it doesn't submit any data directly. It only sets up the input
// values so that when the form is submitted, the values selected in this component are submitted as well.
export default {
  components: { GlFormRadioGroup, GlFormRadio },
  props: {
    userType: {
      type: String,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
    licenseAllowsAuditorUser: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      currentUserType: this.userType,
    };
  },
  computed: {
    userTypeItems() {
      USER_TYPE_ADMIN.description = this.isCurrentUser
        ? s__(
            'AdminUsers|Full access to all groups, projects, users, features, and the Admin area. You cannot remove your own administrator access.',
          )
        : s__(
            'AdminUsers|Full access to all groups, projects, users, features, and the Admin area.',
          );

      return this.licenseAllowsAuditorUser
        ? [USER_TYPE_REGULAR, USER_TYPE_AUDITOR, USER_TYPE_ADMIN]
        : [USER_TYPE_REGULAR, USER_TYPE_ADMIN];
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <label class="gl-mb-0">{{ s__('AdminUsers|User type') }}</label>
    <p class="gl-text-subtle">
      {{ s__('AdminUsers|Define user access to groups, projects, resources, and the Admin area.') }}
    </p>

    <gl-form-radio-group
      v-model="currentUserType"
      name="user[access_level]"
      class="gl-flex gl-flex-col gl-gap-3"
    >
      <gl-form-radio
        v-for="item in userTypeItems"
        :key="item.value"
        :value="item.value"
        :disabled="isCurrentUser"
        :data-testid="`user-type-${item.value}`"
      >
        {{ item.text }}
        <template #help>{{ item.description }}</template>
      </gl-form-radio>
    </gl-form-radio-group>
  </div>
</template>
