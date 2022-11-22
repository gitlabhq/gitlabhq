<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

import {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
} from '../../constants';
import OkrActionsSplitButton from './okr_actions_split_button.vue';
import WorkItemLinksForm from './work_item_links_form.vue';

export default {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  components: {
    GlButton,
    OkrActionsSplitButton,
    WorkItemLinksForm,
  },
  props: {
    workItemType: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isShownAddForm: false,
      isOpen: true,
      error: null,
      formType: null,
      childType: null,
    };
  },
  computed: {
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? s__('WorkItem|Collapse tasks') : s__('WorkItem|Expand tasks');
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
    showAddForm(formType, childType) {
      this.isOpen = true;
      this.isShownAddForm = true;
      this.formType = formType;
      this.childType = childType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.isShownAddForm = false;
    },
  },
};
</script>

<template>
  <div
    class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-bg-gray-10 gl-mt-4"
    data-testid="work-item-tree"
  >
    <div
      class="gl-px-5 gl-py-3 gl-display-flex gl-justify-content-space-between"
      :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': isOpen }"
    >
      <div class="gl-display-flex gl-flex-grow-1">
        <h5 class="gl-m-0 gl-line-height-24">
          {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].title }}
        </h5>
      </div>
      <okr-actions-split-button
        @showCreateObjectiveForm="
          showAddForm($options.FORM_TYPES.create, $options.WORK_ITEM_TYPE_ENUM_OBJECTIVE)
        "
        @showAddObjectiveForm="
          showAddForm($options.FORM_TYPES.add, $options.WORK_ITEM_TYPE_ENUM_OBJECTIVE)
        "
        @showCreateKeyResultForm="
          showAddForm($options.FORM_TYPES.create, $options.WORK_ITEM_TYPE_ENUM_KEY_RESULT)
        "
        @showAddKeyResultForm="
          showAddForm($options.FORM_TYPES.add, $options.WORK_ITEM_TYPE_ENUM_KEY_RESULT)
        "
      />
      <div class="gl-border-l-1 gl-border-l-solid gl-border-l-gray-100 gl-pl-3 gl-ml-3">
        <gl-button
          category="tertiary"
          size="small"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="toggle-tree"
          @click="toggle"
        />
      </div>
    </div>
    <div
      v-if="isOpen"
      class="gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
      :class="{ 'gl-p-5 gl-pb-3': !error }"
      data-testid="tree-body"
    >
      <div v-if="!isShownAddForm && !error" data-testid="tree-empty">
        <p class="gl-mb-3">
          {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].empty }}
        </p>
      </div>
      <work-item-links-form
        v-if="isShownAddForm"
        ref="wiLinksForm"
        data-testid="add-tree-form"
        :issuable-gid="workItemId"
        :form-type="formType"
        :children-type="childType"
        @cancel="hideAddForm"
      />
    </div>
  </div>
</template>
