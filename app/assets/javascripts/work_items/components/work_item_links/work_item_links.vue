<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import WorkItemLinksForm from './work_item_links_form.vue';

export default {
  components: {
    GlButton,
    WorkItemLinksForm,
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isShownAddForm: false,
      isOpen: true,
      children: [],
    };
  },
  computed: {
    // Only used for children for now but should be extended later to support parents and siblings
    isChildrenEmpty() {
      return this.children.length === 0;
    },
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen
        ? s__('WorkItem|Collapse child items')
        : s__('WorkItem|Expand child items');
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
    toggleAddForm() {
      this.isShownAddForm = !this.isShownAddForm;
    },
  },
  i18n: {
    title: s__('WorkItem|Child items'),
    emptyStateMessage: s__(
      'WorkItem|No child items are currently assigned. Use child items to prioritize tasks that your team should complete in order to accomplish your goals!',
    ),
    addChildButtonLabel: s__('WorkItem|Add a child'),
  },
};
</script>

<template>
  <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100">
    <div
      class="gl-p-4 gl-display-flex gl-justify-content-space-between"
      :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': isOpen }"
    >
      <h5 class="gl-m-0 gl-line-height-32">{{ $options.i18n.title }}</h5>
      <div class="gl-border-l-1 gl-border-l-solid gl-border-l-gray-50 gl-pl-4">
        <gl-button
          category="tertiary"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="toggle-links"
          @click="toggle"
        />
      </div>
    </div>
    <div v-if="isOpen" class="gl-bg-gray-10 gl-p-4" data-testid="links-body">
      <div v-if="isChildrenEmpty" class="gl-px-8" data-testid="links-empty">
        <p>
          {{ $options.i18n.emptyStateMessage }}
        </p>
        <gl-button
          v-if="!isShownAddForm"
          category="secondary"
          variant="confirm"
          data-testid="toggle-add-form"
          @click="toggleAddForm"
        >
          {{ $options.i18n.addChildButtonLabel }}
        </gl-button>
        <work-item-links-form v-else data-testid="add-links-form" @cancel="toggleAddForm" />
      </div>
    </div>
  </div>
</template>
