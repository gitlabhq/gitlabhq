<script>
import { GlFormRadioGroup, GlFormRadio, GlCard, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import AdminRoleDropdown from 'ee_component/admin/users/components/user_type/admin_role_dropdown.vue';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import AccessSummarySection from './access_summary_section.vue';

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

// This component is rendered inside an HTML form, so it doesn't submit any data directly. It only sets up the input
// values so that when the form is submitted, the values selected in this component are submitted as well.
export default {
  i18n: {
    regularRole: s__(
      'AdminUsers|Based on member role in groups and projects. %{linkStart}Learn more about member roles.%{linkEnd}',
    ),
    auditorRole: s__(
      'AdminUsers|May be directly added to groups and projects. %{linkStart}Learn more about auditor role.%{linkEnd}',
    ),
    settingsText: s__(
      'AdminUsers|Requires at least Maintainer role in specific groups and projects.',
    ),
  },
  components: {
    GlFormRadioGroup,
    GlFormRadio,
    GlCard,
    GlLink,
    GlIcon,
    GlSprintf,
    AccessSummarySection,
    AdminRoleDropdown,
  },
  mixins: [glFeatureFlagsMixin()],
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
    adminRoleId: {
      type: Number,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      currentUserType: this.userType,
    };
  },
  computed: {
    selectedUserTypeName() {
      return this.userTypeItems.find(({ value }) => value === this.currentUserType)?.text;
    },
    isRegularSelected() {
      return this.currentUserType === USER_TYPE_REGULAR.value;
    },
    isAuditorSelected() {
      return this.currentUserType === USER_TYPE_AUDITOR.value;
    },
    isAdminSelected() {
      return this.currentUserType === USER_TYPE_ADMIN.value;
    },
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
    canChangeAdminRole() {
      return (
        this.glFeatures.customRoles && this.glFeatures.customAdminRoles && !this.isAdminSelected
      );
    },
  },
  ROLES_DOC_LINK: helpPagePath('user/permissions'),
  AUDITOR_USER_DOC_LINK: helpPagePath('administration/auditor_users'),
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

    <gl-card class="gl-mb-7 gl-bg-transparent">
      <div class="gl-mb-4" data-testid="summary-header">
        <label class="gl-mb-0">
          <gl-sprintf :message="s__('AdminUsers|Access summary for %{userType} user')">
            <template #userType>{{ selectedUserTypeName }}</template>
          </gl-sprintf>
        </label>
        <p v-if="canChangeAdminRole" class="gl-mb-0 gl-text-subtle">
          {{ s__('AdminUsers|Review and set Admin area access with a custom admin role.') }}
        </p>
      </div>

      <access-summary-section icon="admin" :header-text="__('Admin area')" class="gl-mb-4">
        <admin-role-dropdown v-if="canChangeAdminRole" :role-id="adminRoleId" class="gl-mt-1" />

        <template v-else-if="isAdminSelected">
          <gl-icon name="check" variant="success" />
          {{ s__('AdminUsers|Full read and write access.') }}
        </template>

        <template v-if="!canChangeAdminRole && !isAdminSelected" #list>
          <li>{{ s__('AdminUsers|No access.') }}</li>
        </template>
      </access-summary-section>

      <access-summary-section icon="group" :header-text="__('Groups and projects')" class="gl-mb-4">
        <template v-if="isRegularSelected" #list>
          <li>
            <gl-sprintf :message="$options.i18n.regularRole">
              <template #link="{ content }">
                <gl-link :href="$options.ROLES_DOC_LINK" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </li>
        </template>

        <template v-else-if="isAuditorSelected" #list>
          <li>{{ s__('AdminUsers|Read access to all groups and projects.') }}</li>
          <li>
            <gl-sprintf :message="$options.i18n.auditorRole">
              <template #link="{ content }">
                <gl-link :href="$options.AUDITOR_USER_DOC_LINK" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </li>
        </template>

        <template v-if="isAdminSelected">
          <gl-icon name="check" variant="success" />
          {{ s__('AdminUsers|Full read and write access.') }}
        </template>
      </access-summary-section>

      <access-summary-section
        icon="settings"
        :header-text="s__('AdminUsers|Groups and project settings')"
        class="gl-mb-1"
      >
        <template v-if="isRegularSelected || isAuditorSelected" #list>
          <li>{{ $options.i18n.settingsText }}</li>
        </template>

        <template v-if="isAdminSelected">
          <gl-icon name="check" variant="success" />
          {{ s__('AdminUsers|Full read and write access.') }}
        </template>
      </access-summary-section>
    </gl-card>
  </div>
</template>
