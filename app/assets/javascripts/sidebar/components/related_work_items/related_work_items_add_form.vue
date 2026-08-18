<script>
import { GlModal, GlFormGroup, GlButton, GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import { CREATION_CONTEXT_RELATED_ITEM } from '~/work_items/constants';
import recentlyViewedWorkItemsQuery from '~/sidebar/queries/recently_viewed_work_items.query.graphql';
import {
  MR_WORK_ITEM_RELATIONSHIP_TYPES,
  MR_WORK_ITEM_RELATIONSHIP_OPTIONS,
} from '~/sidebar/constants';

export default {
  name: 'RelatedWorkItemsAddForm',
  components: {
    GlModal,
    GlFormGroup,
    GlButton,
    GlCollapsibleListbox,
    GlIcon,
    CreateWorkItemModal,
    WorkItemTokenInput,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    fullPath: {
      type: String,
      required: true,
    },
    mergeRequestId: {
      type: String,
      required: true,
    },
    mergeRequestTitle: {
      type: String,
      required: false,
      default: '',
    },
    mergeRequestReference: {
      type: String,
      required: false,
      default: '',
    },
    namespaces: {
      type: Array,
      required: false,
      default: () => [],
    },
    relationshipTypes: {
      type: Array,
      required: false,
      default: () => MR_WORK_ITEM_RELATIONSHIP_OPTIONS,
    },
  },
  emits: ['hide', 'link', 'created'],
  modalId: 'add-related-work-item-modal',
  creationContext: CREATION_CONTEXT_RELATED_ITEM,
  i18n: {
    title: s__('WorkItem|Link work item'),
    relationshipLabel: s__('WorkItem|Relationship'),
    recentlyVisited: s__('WorkItem|Recently visited'),
    createNewItem: s__('WorkItem|Create new item'),
    add: __('Add'),
    cancel: __('Cancel'),
    fetchError: s__('WorkItem|Something went wrong while fetching recently viewed items.'),
  },
  data() {
    return {
      workItemsToAdd: [],
      isCreateModalVisible: false,
      selectedRelationship: MR_WORK_ITEM_RELATIONSHIP_TYPES.closing,
      selectedNamespace: null,
      recentlyViewedItems: [],
    };
  },
  apollo: {
    recentlyViewedItems: {
      query: recentlyViewedWorkItemsQuery,
      skip() {
        return !this.visible;
      },
      update({ currentUser } = {}) {
        return (currentUser?.recentlyViewedIssues ?? []).map((item) => ({
          id: item.id,
          title: item.title,
          reference: item.reference,
          iconName: item.workItemType?.iconName || 'work-item-issue',
        }));
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.fetchError,
          error,
          captureError: true,
        });
      },
    },
  },
  computed: {
    selectedRelationshipText() {
      if (!this.selectedRelationship) {
        return this.relationshipTypes[0]?.text ?? '';
      }
      return this.relationshipTypes.find((r) => r.value === this.selectedRelationship)?.text ?? '';
    },
    hasSelection() {
      return this.workItemsToAdd.length > 0;
    },
  },
  watch: {
    visible(newVal) {
      if (!newVal) {
        this.workItemsToAdd = [];
      }
    },
  },
  methods: {
    handleHide() {
      this.$emit('hide');
    },
    handleAdd() {
      this.$emit('link', {
        workItems: this.workItemsToAdd,
        linkType: this.selectedRelationship,
      });
    },
    handleSelectItem(item) {
      this.$emit('link', {
        workItems: [item],
        linkType: this.selectedRelationship,
      });
    },
    openCreateModal() {
      this.isCreateModalVisible = true;
    },
    handleWorkItemCreated(workItem) {
      // The new work item is already linked to the merge request via the
      // workItemCreate development widget, so no follow-up relation mutation is
      // needed here. We hand the new item up so the parent can show it.
      this.isCreateModalVisible = false;
      this.$emit('created', { workItem, linkType: this.selectedRelationship });
    },
  },
};
</script>

<template>
  <div>
    <gl-modal
      :modal-id="$options.modalId"
      :visible="visible"
      :title="$options.i18n.title"
      size="md"
      hide-footer
      @hide="handleHide"
    >
      <!-- Relationship selector -->
      <gl-form-group :label="$options.i18n.relationshipLabel" class="gl-w-1/3">
        <gl-collapsible-listbox
          v-model="selectedRelationship"
          block
          :items="relationshipTypes"
          :toggle-text="selectedRelationshipText"
        />
      </gl-form-group>

      <!-- Search + namespace selector row -->
      <div class="gl-mb-4 gl-flex gl-items-center gl-gap-3">
        <work-item-token-input
          v-model="workItemsToAdd"
          class="gl-grow"
          :full-path="fullPath"
          parent-work-item-id=""
          :are-work-items-to-add-valid="true"
        />
        <gl-collapsible-listbox
          v-if="namespaces.length"
          v-model="selectedNamespace"
          :items="namespaces"
          :toggle-text="selectedNamespace || fullPath"
        />
      </div>

      <!-- Recently visited items -->
      <div v-if="recentlyViewedItems.length" class="gl-mb-2">
        <p class="gl-mb-2 gl-text-sm gl-font-bold">
          {{ $options.i18n.recentlyVisited }}
        </p>
        <ul class="gl-m-0 gl-list-none gl-p-0">
          <li
            v-for="item in recentlyViewedItems"
            :key="item.id"
            class="gl-flex gl-cursor-pointer gl-items-center gl-justify-between gl-gap-3 gl-rounded-base gl-px-2 gl-py-3 hover:gl-bg-subtle"
            data-testid="recently-viewed-item"
            @click="handleSelectItem(item)"
          >
            <div class="gl-flex gl-items-center gl-gap-2 gl-truncate">
              <gl-icon :name="item.iconName" class="gl-shrink-0" />
              <span class="gl-truncate">{{ item.title }}</span>
            </div>
            <span
              v-if="item.reference"
              class="gl-shrink-0 gl-text-sm gl-text-subtle"
              data-testid="recently-viewed-item-reference"
              >{{ item.reference }}</span
            >
          </li>
        </ul>
      </div>

      <!-- Footer actions -->
      <div class="gl-border-t gl-flex gl-items-center gl-pt-3">
        <gl-button
          variant="link"
          icon="issue-new"
          data-testid="add-work-item-create"
          @click="openCreateModal"
        >
          {{ $options.i18n.createNewItem }}
        </gl-button>
        <div class="gl-ml-auto gl-flex gl-gap-3">
          <gl-button data-testid="add-work-item-cancel" @click="handleHide">
            {{ $options.i18n.cancel }}
          </gl-button>
          <gl-button
            variant="confirm"
            :disabled="!hasSelection"
            data-testid="add-work-item-confirm"
            @click="handleAdd"
          >
            {{ $options.i18n.add }}
          </gl-button>
        </div>
      </div>
    </gl-modal>

    <create-work-item-modal
      :full-path="fullPath"
      :visible="isCreateModalVisible"
      :creation-context="$options.creationContext"
      always-show-work-item-type-select
      allow-any-namespace
      allow-projects-only
      :merge-request-id="mergeRequestId"
      :merge-request-title="mergeRequestTitle"
      :merge-request-reference="mergeRequestReference"
      :merge-request-link-type="selectedRelationship"
      hide-button
      @hide-modal="isCreateModalVisible = false"
      @work-item-created="handleWorkItemCreated"
    />
  </div>
</template>
