<script>
import { mapActions, mapState } from 'vuex';

import RegionDropdown from './region_dropdown.vue';
import RoleNameDropdown from './role_name_dropdown.vue';
import SecurityGroupDropdown from './security_group_dropdown.vue';
import SubnetDropdown from './subnet_dropdown.vue';
import VPCDropdown from './vpc_dropdown.vue';

export default {
  components: {
    RegionDropdown,
    RoleNameDropdown,
    SecurityGroupDropdown,
    SubnetDropdown,
    VPCDropdown,
  },
  computed: {
    ...mapState(['isLoadingRegions', 'loadingRegionsError', 'regions', 'selectedRegion']),
  },
  mounted() {
    this.fetchRegions();
  },
  methods: {
    ...mapActions(['fetchRegions', 'setRegion']),
  },
};
</script>
<template>
  <form name="eks-cluster-configuration-form">
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">
        {{ s__('ClusterIntegration|Role name') }}
      </label>
      <role-name-dropdown />
    </div>
    <div class="form-group">
      <label class="label-bold" name="role" for="eks-role">
        {{ s__('ClusterIntegration|Region') }}
      </label>
      <region-dropdown
        :value="selectedRegion"
        :regions="regions"
        :error="loadingRegionsError"
        :loading="isLoadingRegions"
        @input="setRegion({ region: $event })"
      />
    </div>
  </form>
</template>
