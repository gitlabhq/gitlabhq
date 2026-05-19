<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  components: { GlCollapsibleListbox },
  inject: {
    manageMemberRolesPath: { default: null },
  },
  props: {
    roles: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    headerText: {
      type: String,
      required: false,
      default: s__('MemberRole|Change role'),
    },
  },
  computed: {
    manageRolesText() {
      return this.manageMemberRolesPath ? s__('MemberRole|Manage roles') : '';
    },
  },
  methods: {
    navigateToManageMemberRolesPage() {
      visitUrl(this.manageMemberRolesPath);
    },
    emitRole(selectedValue) {
      const role = this.roles.flatten.find(({ value }) => value === selectedValue);
      this.$emit('input', role);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="headerText"
    :reset-button-label="manageRolesText"
    :items="roles.formatted"
    :selected="value && value.value"
    :loading="loading"
    block
    fluid-width
    @reset="navigateToManageMemberRolesPage"
    @select="emitRole"
  >
    <template #list-item="{ item }">
      <div class="gl-line-clamp-2" data-testid="role-data">
        <span data-testid="role-name">{{ item.text }}</span>
      </div>
      <div
        v-if="item.dropdownDescription || item.description"
        class="gl-mt-1 gl-whitespace-normal gl-text-sm"
        data-testid="role-description"
      >
        <span class="gl-text-subtle">{{ item.dropdownDescription || item.description }}</span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
