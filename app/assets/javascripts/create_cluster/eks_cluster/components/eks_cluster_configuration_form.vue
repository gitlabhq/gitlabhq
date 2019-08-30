<script>
import RoleNameDropdown from './role_name_dropdown.vue';
import SecurityGroupDropdown from './security_group_dropdown.vue';
import SubnetDropdown from './subnet_dropdown.vue';
import VPCDropdown from './vpc_dropdown.vue';

export default {
  components: {
    RoleNameDropdown,
    SecurityGroupDropdown,
    SubnetDropdown,
    VPCDropdown,
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form"></form>
</template>
