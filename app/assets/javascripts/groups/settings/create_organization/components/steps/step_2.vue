<script>
import { GlSprintf } from '@gitlab/ui';
import Draggable from '~/lib/utils/vue3compat/draggable_compat.vue';
import { n__, sprintf } from '~/locale';
import OrganizationGroupCard from '../organization_group_card.vue';
import OrganizationCard from '../organization_card.vue';
import BaseStep from './base_step.vue';

const DRAGGING_CSS_CLASS = 'organizations-reconciliation-draggable-dragging';
const FALLBACK_CSS_CLASS = 'organizations-reconciliation-draggable-fallback';
const DRAGGING_DISABLED_CSS_CLASS = 'organizations-reconciliation-draggable-disabled';

export default {
  name: 'ReconciliationStep2',
  FALLBACK_CSS_CLASS,
  DRAGGING_DISABLED_CSS_CLASS,
  components: {
    BaseStep,
    OrganizationCard,
    OrganizationGroupCard,
    Draggable,
    GlSprintf,
  },
  inheritAttrs: false,
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
    };
  },
  computed: {
    stepTitle() {
      const count = this.initialDefaultOrgGroupIds.length;

      return sprintf(
        n__(
          'Organization|You have %{boldStart}%{count}%{boldEnd} other top-level group. Drag unassigned groups to your organization, or leave the structure as is. Unassigned groups will not be included in the organization.',
          'Organization|You have %{boldStart}%{count}%{boldEnd} other top-level groups. Drag unassigned groups to your organization, or leave the structure as is. Unassigned groups will not be included in the organization.',
          count,
        ),
        { count },
      );
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
    isDraggable(group) {
      return this.initialDefaultOrgGroupIds.includes(group.id);
    },
    shouldShowDropzone(isDefaultOrganization, groups) {
      if (isDefaultOrganization) {
        return this.initialDefaultOrgGroupIds.length !== groups.length;
      }

      return true;
    },
    onDraggableInput(changedOrganization, groups) {
      this.pendingChanges[changedOrganization.id] = groups;
    },
    onDraggableEnd() {
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
    onMove(event) {
      // Prevent reordering items that have dragging disabled
      if (event.related.classList.contains(DRAGGING_DISABLED_CSS_CLASS)) {
        return 1;
      }

      return true;
    },
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Assign top-level groups')">
    <template #description>
      <p>
        <gl-sprintf :message="stepTitle">
          <template #bold="{ content }">
            <span class="gl-font-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
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
            <template #default="{ isDefaultOrganization }">
              <draggable
                class="organizations-reconciliation-draggable gl-flex gl-min-h-11 gl-flex-col gl-gap-4"
                chosen-class="gl-shadow-md"
                :value="organization.groups.nodes"
                group="organizationGroups"
                item-key="id"
                :fallback-on-body="true"
                :force-fallback="true"
                :fallback-class="$options.FALLBACK_CSS_CLASS"
                :filter="`.${$options.DRAGGING_DISABLED_CSS_CLASS}`"
                :move="onMove"
                @input="onDraggableInput(organization, $event)"
                @end="onDraggableEnd"
                @choose="onChoose"
                @unchoose="onUnchoose"
              >
                <organization-group-card
                  v-for="group in organization.groups.nodes"
                  :key="group.id"
                  :group="group"
                  :organization-visibility="organization.visibility"
                  class="gl-select-none"
                  :class="{
                    'gl-border': isDefaultOrganization,
                    'hover:gl-cursor-grab hover:gl-shadow-md': isDraggable(group),
                    [$options.DRAGGING_DISABLED_CSS_CLASS]: !isDraggable(group),
                  }"
                />
              </draggable>
              <div
                v-if="shouldShowDropzone(isDefaultOrganization, organization.groups.nodes)"
                data-testid="organization-dropzone"
                class="organizations-reconciliation-draggable-dropzone gl-border-secondary gl-pointer-events-none gl-absolute gl-flex gl-h-11 gl-w-full gl-items-center gl-justify-center gl-rounded-md gl-border-dashed gl-border-strong"
              >
                <p class="gl-m-0 gl-text-secondary">{{ s__('Organization|Drop groups here') }}</p>
              </div>
            </template>
          </organization-card>
        </div>
      </div>
    </div>
  </base-step>
</template>
