<script>
import { GlFormRadioGroup, GlFormRadio, GlCard, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import RegularAccessSummary from './regular_access_summary.vue';
import AdminAccessSummary from './admin_access_summary.vue';

export const USER_TYPE_REGULAR = {
  value: 'regular',
  text: s__('AdminUsers|Regular'),
  description: s__('AdminUsers|Access to their groups and projects.'),
};
// description is set dynamically based on isCurrentUser prop.
export const USER_TYPE_ADMIN = { value: 'admin', text: s__('AdminUsers|Administrator') };

// This component is rendered inside an HTML form, so it doesn't submit any data directly. It only sets up the input
// values so that when the form is submitted, the values selected in this component are submitted as well.
export default {
  components: {
    GlFormRadioGroup,
    GlFormRadio,
    GlCard,
    GlSprintf,
    RegularAccessSummary,
    AdminAccessSummary,
  },
  props: {
    userType: {
      type: String,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
    userTypes: {
      type: Array,
      required: false,
      default: () => [USER_TYPE_REGULAR, USER_TYPE_ADMIN],
    },
  },
  data() {
    return {
      currentUserType: this.userType,
    };
  },
  computed: {
    selectedUserTypeName() {
      return this.userTypes.find(({ value }) => value === this.currentUserType)?.text;
    },
    isRegularSelected() {
      return this.currentUserType === USER_TYPE_REGULAR.value;
    },
    isAdminSelected() {
      return this.currentUserType === USER_TYPE_ADMIN.value;
    },
  },
  created() {
    USER_TYPE_ADMIN.description = this.isCurrentUser
      ? s__(
          'AdminUsers|Full access to all groups, projects, users, features, and the Admin area. You cannot remove your own administrator access.',
        )
      : s__('AdminUsers|Full access to all groups, projects, users, features, and the Admin area.');
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
      class="gl-mb-3 gl-flex gl-flex-col gl-gap-3"
      @input="$emit('access-change', $event)"
    >
      <gl-form-radio
        v-for="item in userTypes"
        :key="item.value"
        :value="item.value"
        :disabled="isCurrentUser"
        :data-testid="`user-type-${item.value}`"
      >
        {{ item.text }}
        <template #help>{{ item.description }}</template>
      </gl-form-radio>
    </gl-form-radio-group>

    <gl-card class="gl-mb-7 gl-bg-transparent">
      <div class="gl-mb-4">
        <label class="gl-mb-0">
          <gl-sprintf :message="s__('AdminUsers|Access summary for %{userType} user')">
            <template #userType>{{ selectedUserTypeName }}</template>
          </gl-sprintf>
        </label>
        <slot name="description"></slot>
      </div>

      <slot>
        <regular-access-summary v-if="isRegularSelected" />
        <admin-access-summary v-else-if="isAdminSelected" />
      </slot>
    </gl-card>
  </div>
</template>
