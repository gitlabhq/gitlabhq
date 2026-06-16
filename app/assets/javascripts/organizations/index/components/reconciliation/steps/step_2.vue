<script>
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { isDefaultOrganization } from '~/organizations/shared/utils';
import OrganizationGroupCard from '../organization_group_card.vue';
import OrganizationCard from '../organization_card.vue';
import BaseStep from './base_step.vue';

const DRAGGING_CSS_CLASS = 'organizations-reconciliation-draggable-dragging';
const FALLBACK_CSS_CLASS = 'organizations-reconciliation-draggable-fallback';

export default {
  name: 'ReconciliationStep2',
  FALLBACK_CSS_CLASS,
  components: {
    BaseStep,
    OrganizationCard,
    OrganizationGroupCard,
    Draggable,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
    initialDefaultOrgGroupIds: {
      type: Array,
      required: true,
    },
  },
  emits: ['update'],
  data() {
    return {
      pendingChanges: {},
      activeDragGroupId: null,
    };
  },
  computed: {
    currentDefaultOrgGroupIds() {
      const defaultOrg = this.organizations.find(isDefaultOrganization);

      return defaultOrg ? defaultOrg.groups.nodes.map((group) => group.id) : [];
    },
    shouldShowDefaultOrganizationDropzone() {
      if (this.activeDragGroupId) {
        return this.initialDefaultOrgGroupIds.includes(this.activeDragGroupId);
      }

      return this.initialDefaultOrgGroupIds.length !== this.currentDefaultOrgGroupIds.length;
    },
  },
  beforeDestroy() {
    document.body.classList.remove(DRAGGING_CSS_CLASS);

    // There is a bug in SortableJS where the fallback element is not removed when the instance is destroyed.
    // This code manually removes the fallback element if the modal is closed while dragging.
    const fallbackEl = document.querySelector(`.${FALLBACK_CSS_CLASS}`);
    if (fallbackEl) {
      fallbackEl.parentNode.removeChild(fallbackEl);
    }
  },
  methods: {
    draggableGroup(organization) {
      if (isDefaultOrganization(organization)) {
        return {
          name: 'organizationGroups',
          pull: true,
          put: () => this.initialDefaultOrgGroupIds.includes(this.activeDragGroupId),
        };
      }

      return 'organizationGroups';
    },
    shouldShowDropzone(organization) {
      if (isDefaultOrganization(organization)) {
        return this.shouldShowDefaultOrganizationDropzone;
      }

      return true;
    },
    onDraggableStart(organization, { oldIndex }) {
      this.activeDragGroupId = organization.groups.nodes[oldIndex].id;
    },
    onDraggableInput(changedOrganization, groups) {
      this.pendingChanges[changedOrganization.id] = groups;
    },
    onDraggableEnd() {
      this.activeDragGroupId = null;

      const updatedOrganizations = this.organizations.map((organization) => {
        const pendingChange = this.pendingChanges[organization.id];

        if (!pendingChange) {
          return organization;
        }

        return {
          ...organization,
          groups: {
            ...organization.groups,
            nodes: pendingChange,
          },
        };
      });

      this.pendingChanges = {};

      this.$emit('update', updatedOrganizations);
    },
    onChoose() {
      document.body.classList.add(DRAGGING_CSS_CLASS);
    },
    onUnchoose() {
      document.body.classList.remove(DRAGGING_CSS_CLASS);
    },
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Assign top-level groups')">
    <template #description>
      <p>
        {{
          s__(
            'Organization|Drag groups between Organizations to set up your structure. Most companies only need one.',
          )
        }}
      </p>
    </template>

    <div class="gl-p-2">
      <div class="-gl-m-2 gl-flex gl-flex-wrap gl-pb-4">
        <div
          v-for="organization in organizations"
          :key="organization.id"
          class="gl-w-1/2 gl-p-2 first:gl-ml-auto last:gl-mr-auto @lg:gl-w-1/3"
        >
          <organization-card :organization="organization">
            <draggable
              class="organizations-reconciliation-draggable gl-flex gl-min-h-11 gl-flex-col gl-gap-4"
              chosen-class="gl-shadow-md"
              :value="organization.groups.nodes"
              :group="draggableGroup(organization)"
              item-key="id"
              :fallback-on-body="true"
              :force-fallback="true"
              :fallback-class="$options.FALLBACK_CSS_CLASS"
              @start="onDraggableStart(organization, $event)"
              @input="onDraggableInput(organization, $event)"
              @end="onDraggableEnd"
              @choose="onChoose"
              @unchoose="onUnchoose"
            >
              <organization-group-card
                v-for="group in organization.groups.nodes"
                :key="group.id"
                :group="group"
                class="gl-select-none hover:gl-cursor-grab hover:gl-shadow-md"
              />
            </draggable>
            <div
              v-if="shouldShowDropzone(organization)"
              data-testid="organization-dropzone"
              class="organizations-reconciliation-draggable-dropzone gl-border-secondary gl-pointer-events-none gl-absolute gl-flex gl-h-11 gl-w-full gl-items-center gl-justify-center gl-rounded-md gl-border-dashed gl-border-strong"
            >
              <p class="gl-m-0 gl-text-secondary">{{ s__('Organization|Drop groups here') }}</p>
            </div>
          </organization-card>
        </div>
      </div>
    </div>
  </base-step>
</template>
