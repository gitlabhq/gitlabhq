<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';

export default {
  name: 'RoleDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDesktop: false,
    };
  },
  mounted() {
    this.isDesktop = bp.isDesktop();
  },
  methods: {
    handleSelect() {
      // Vuex action will be called here to make API request and update `member.accessLevel`
    },
  },
};
</script>

<template>
  <gl-dropdown
    :right="!isDesktop"
    :text="member.accessLevel.stringValue"
    :header-text="__('Change permissions')"
  >
    <gl-dropdown-item
      v-for="(value, name) in member.validRoles"
      :key="value"
      is-check-item
      :is-checked="value === member.accessLevel.integerValue"
      @click="handleSelect"
    >
      {{ name }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
