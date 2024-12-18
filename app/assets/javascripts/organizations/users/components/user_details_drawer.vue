<script>
import { GlCollapsibleListbox, GlDrawer, GlTooltipDirective } from '@gitlab/ui';
import UserAvatar from '~/vue_shared/components/users_table/user_avatar.vue';
import {
  ACCESS_LEVEL_DEFAULT_STRING,
  ACCESS_LEVEL_LABEL,
  ACCESS_LEVEL_OWNER_STRING,
} from '~/organizations/shared/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import organizationUserUpdateMutation from '~/organizations/users/graphql/mutations/organization_user_update.mutation.graphql';
import { createAlert } from '~/alert';

export default {
  name: 'UserDetailsDrawer',
  components: {
    GlCollapsibleListbox,
    GlDrawer,
    UserAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['paths'],
  i18n: {
    title: s__('Organization|Organization user details'),
    roleListboxLabel: s__('Organization|Organization role'),
    disabledRoleListboxTooltipText: s__('Organization|Organizations must have at least one owner.'),
    errorMessage: s__(
      'Organization|An error occurred updating the organization role. Please try again.',
    ),
    successMessage: s__('Organization|Organization role was updated successfully.'),
  },
  roleListboxItems: [
    {
      text: ACCESS_LEVEL_LABEL[ACCESS_LEVEL_DEFAULT_STRING],
      value: ACCESS_LEVEL_DEFAULT_STRING,
    },
    {
      text: ACCESS_LEVEL_LABEL[ACCESS_LEVEL_OWNER_STRING],
      value: ACCESS_LEVEL_OWNER_STRING,
    },
  ],
  props: {
    user: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      initialAccessLevel: this.user?.accessLevel.stringValue,
      selectedAccessLevel: this.user?.accessLevel.stringValue,
      loading: false,
    };
  },
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    roleListboxDisabled() {
      return this.user?.isLastOwner;
    },
    roleListboxTooltip() {
      return this.roleListboxDisabled ? this.$options.i18n.disabledRoleListboxTooltipText : null;
    },
  },
  watch: {
    user(value) {
      this.initialAccessLevel = value?.accessLevel.stringValue;
      this.selectedAccessLevel = value?.accessLevel.stringValue;
    },
  },
  methods: {
    setLoading(value) {
      this.loading = value;
      this.$emit('loading', value);
    },
    onUpdateSuccess() {
      this.initialAccessLevel = this.selectedAccessLevel;
      this.$toast.show(this.$options.i18n.successMessage);
      this.$emit('role-change');
    },
    async onRoleSelect() {
      this.setLoading(true);

      try {
        const {
          data: {
            organizationUserUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: organizationUserUpdateMutation,
          variables: {
            input: {
              id: this.user.gid,
              accessLevel: this.selectedAccessLevel,
            },
          },
        });

        if (errors.length) {
          createAlert({ message: errors[0] });
          return;
        }

        this.onUpdateSuccess();
      } catch (error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      } finally {
        this.setLoading(false);
      }
    },
    close() {
      this.$emit('close');
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    v-if="user"
    open
    header-sticky
    :header-height="drawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="close"
  >
    <template #title>
      <h4 class="gl-m-0">{{ $options.i18n.title }}</h4>
    </template>
    <template #default>
      <div>
        <user-avatar :user="user" :admin-user-path="paths.adminUser" />
      </div>
      <div>
        <h5>{{ $options.i18n.roleListboxLabel }}</h5>
        <div
          v-gl-tooltip="{ disabled: !roleListboxTooltip, title: roleListboxTooltip }"
          class="gl-rounded-base focus:gl-focus"
          :tabindex="roleListboxDisabled && 0"
        >
          <gl-collapsible-listbox
            v-model="selectedAccessLevel"
            block
            toggle-class="gl-form-input-xl"
            :disabled="roleListboxDisabled"
            :items="$options.roleListboxItems"
            :loading="loading"
            @select="onRoleSelect"
          />
        </div>
      </div>
    </template>
  </gl-drawer>
</template>
