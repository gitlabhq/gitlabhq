<script>
import { GlBadge, GlButton, GlTooltipDirective } from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlBadge,
    GlButton,
    LocalStorageSync,
    CrudComponent,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    helpContent: {
      type: String,
      required: false,
      default: '',
    },
    count: {
      type: Number,
      required: false,
      default: null,
    },
    hasMergeRequests: {
      type: Boolean,
      required: false,
      default: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    error: {
      type: Boolean,
      required: false,
      default: false,
    },
    mergeRequests: {
      type: Array,
      required: false,
      default: () => [],
    },
    newMergeRequestIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    activeList: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideCount: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      open: true,
      savedOpenState: null,
    };
  },
  computed: {
    toggleButtonLabel() {
      return sprintf(
        this.open
          ? __('Collapse %{section} merge requests')
          : __('Expand %{section} merge requests'),
        {
          section: this.title.toLowerCase(),
        },
      );
    },
    newMergeRequests() {
      return this.mergeRequests.filter((mr) => this.newMergeRequestIds.includes(mr.id));
    },
    newMergeRequestsBadgeText() {
      return sprintf(__('+%{count} new'), { count: this.newMergeRequests.length });
    },
    helpPopoverAriaLabel() {
      return sprintf(__('%{list} list help popover'), { list: this.title });
    },
    storageKey() {
      return `mr_list_${this.id}`;
    },
    isSectionOpen() {
      if (this.savedOpenState === null) return this.open;

      return this.savedOpenState;
    },
  },
  watch: {
    loading(newVal) {
      this.open = newVal || this.hasMergeRequests;
    },
  },
  methods: {
    onCollapsedSection() {
      this.open = false;
      this.savedOpenState = false;
      this.$emit('clear-new');
    },
    onExpandSection() {
      this.open = true;
      this.savedOpenState = true;
    },
  },
};
</script>

<template>
  <local-storage-sync
    :storage-key="storageKey"
    :value="savedOpenState"
    @input="(val) => (savedOpenState = val)"
  >
    <crud-component
      is-collapsible
      :collapsed="!isSectionOpen"
      :toggle-aria-label="toggleButtonLabel"
      body-class="!gl-mx-0 gl-mb-0"
      @collapsed="onCollapsedSection"
      @expanded="onExpandSection"
    >
      <template #title>
        {{ title }}
        <gl-badge v-if="!hideCount" size="sm" data-testid="merge-request-list-count">{{
          count === null ? '-' : count
        }}</gl-badge>
      </template>

      <template #actions>
        <gl-badge
          v-if="!open && newMergeRequests.length"
          :variant="activeList ? 'success' : 'neutral'"
          class="gl-font-bold"
        >
          {{ newMergeRequestsBadgeText }}
        </gl-badge>
        <gl-button
          v-gl-tooltip
          :title="helpContent"
          :aria-label="helpPopoverAriaLabel"
          icon="information-o"
          variant="link"
          class="gl-mr-2 gl-self-center"
        />
      </template>

      <template v-if="!hasMergeRequests && !loading && !error" #empty>
        <p class="gl-pt-1 gl-text-center gl-text-subtle">
          {{ __('No merge requests match this list.') }}
        </p>
        <slot name="drafts"></slot>
      </template>

      <template #default>
        <slot></slot>
        <slot name="drafts"></slot>
      </template>

      <template v-if="open" #pagination>
        <slot name="pagination"></slot>
      </template>
    </crud-component>
  </local-storage-sync>
</template>
