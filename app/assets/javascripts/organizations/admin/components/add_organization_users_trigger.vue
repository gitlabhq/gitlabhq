<script>
import { GlButton } from '@gitlab/ui';
import AddOrganizationUsersModal from './add_organization_users_modal.vue';

export default {
  name: 'AddOrganizationUsersTrigger',
  components: {
    GlButton,
    AddOrganizationUsersModal,
  },
  data() {
    return {
      modalVisible: false,
    };
  },
  methods: {
    openModal() {
      this.modalVisible = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-button variant="confirm" @click="openModal">
      {{ s__('Organization|Invite organization user') }}
    </gl-button>
    <add-organization-users-modal v-model="modalVisible" />
  </div>
</template>
