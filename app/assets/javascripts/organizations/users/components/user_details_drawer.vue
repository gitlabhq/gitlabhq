<script>
import { GlAlert, GlButton, GlCollapsibleListbox, GlDrawer, GlTooltipDirective } from '@gitlab/ui';
import UserAvatar from '~/vue_shared/components/users_table/user_avatar.vue';
import {
  ACCESS_LEVEL_DEFAULT_STRING,
  ACCESS_LEVEL_LABEL,
  ACCESS_LEVEL_OWNER_STRING,
} from '~/organizations/shared/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import organizationUserUpdateMutation from '~/organizations/users/graphql/mutations/organization_user_update.mutation.graphql';
import { createAlert } from '~/alert';

export default {
  name: 'UserDetailsDrawer',
  components: {
    GlAlert,
    GlButton,
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
    removeSelfAsOwnerWarning: s__(
      'Organization|If you proceed with this change you will lose your owner permissions for this organization, including access to this page.',
    ),
    errorMessage: s__(
      'Organization|An error occurred updating the organization role. Please try again.',
    ),
    successMessage: s__('Organization|Organization role was updated successfully.'),
    save: __('Save'),
    cancel: __('Cancel'),
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
    isChangingRole() {
      return this.initialAccessLevel !== this.selectedAccessLevel;
    },
    roleListboxDisabled() {
      return this.user?.isLastOwner;
    },
    roleListboxTooltip() {
      return this.roleListboxDisabled ? this.$options.i18n.disabledRoleListboxTooltipText : null;
    },
    showRemoveSelfAsOwnerWarning() {
      const isUserCurrentUser = this.user?.id === window.gon?.current_user_id;
      const isOwnerRoleSelected = this.selectedAccessLevel === ACCESS_LEVEL_OWNER_STRING;

      return isUserCurrentUser && !isOwnerRoleSelected && this.isChangingRole;
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
    async save() {
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
    cancel() {
      this.selectedAccessLevel = this.initialAccessLevel;
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
        <user-avatar class="gl-mt-3" :user="user" :admin-user-path="paths.adminUser" />
        <hr />
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
          />
        </div>
      </div>
    </template>
    <template #footer>
      <div
        v-if="isChangingRole"
        class="gl-flex gl-flex-col gl-gap-4"
        data-testid="user-details-drawer-footer"
      >
        <gl-alert v-if="showRemoveSelfAsOwnerWarning" variant="warning" :dismissible="false">{{
          $options.i18n.removeSelfAsOwnerWarning
        }}</gl-alert>
        <div class="gl-flex gl-gap-3">
          <gl-button variant="confirm" :disabled="loading" @click="save">{{
            $options.i18n.save
          }}</gl-button>
          <gl-button :disabled="loading" @click="cancel">{{ $options.i18n.cancel }}</gl-button>
        </div>
      </div>
    </template>
  </gl-drawer>
</template>
