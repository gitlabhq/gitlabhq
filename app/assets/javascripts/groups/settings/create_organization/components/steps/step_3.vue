<script>
import OrganizationGroupCard from '../organization_group_card.vue';
import OrganizationCard from '../organization_card.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep3',
  components: {
    BaseStep,
    OrganizationCard,
    OrganizationGroupCard,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
  computed: {
    retainedOrganizations() {
      return this.organizations.filter((org) => org.groups.nodes.length > 0);
    },
    deletedOrganizations() {
      return this.organizations.filter((org) => org.groups.nodes.length === 0);
    },
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Organization summary')">
    <template #description>
      <p>
        {{ s__("Organization|Here's your final structure. Activate when you're happy with it.") }}
      </p>
    </template>

    <div
      v-if="retainedOrganizations.length"
      data-testid="retained-organizations-section"
      class="gl-mb-6"
    >
      <h5 class="gl-heading-5">{{ s__('Organization|Your new structure') }}</h5>
      <div class="gl-flex gl-flex-col gl-gap-4">
        <organization-card
          v-for="organization in retainedOrganizations"
          :key="organization.id"
          :organization="organization"
        >
          <div class="gl-grid gl-grid-cols-2 gl-gap-4 md:gl-grid-cols-3">
            <organization-group-card
              v-for="group in organization.groups.nodes"
              :key="group.id"
              :group="group"
            />
          </div>
        </organization-card>
      </div>
    </div>

    <div v-if="deletedOrganizations.length" data-testid="deleted-organizations-section">
      <h5 class="gl-heading-5">{{ s__('Organization|These Organizations will be deleted') }}</h5>
      <div class="gl-flex gl-flex-col gl-gap-4">
        <organization-card
          v-for="organization in deletedOrganizations"
          :key="organization.id"
          :organization="organization"
        />
      </div>
    </div>
  </base-step>
</template>
