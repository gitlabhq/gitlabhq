<script>
import { GlBadge, GlButton, GlTooltipDirective } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlBadge,
    GlButton,
    CrudComponent,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
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
  },
  data() {
    return {
      open: true,
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
  },
  watch: {
    loading(newVal) {
      this.open = newVal || this.hasMergeRequests;
    },
  },
  methods: {
    onCollapsedSection() {
      this.open = false;
      this.$emit('clear-new');
    },
    onExpandSection() {
      this.open = true;
    },
  },
};
</script>
2

<template>
  <crud-component
    is-collapsible
    :collapsed="!open"
    :toggle-aria-label="toggleButtonLabel"
    body-class="!gl-mx-0 gl-mb-0"
    @collapsed="onCollapsedSection"
    @expanded="onExpandSection"
  >
    <template #title>
      {{ title }}
      <gl-badge v-if="count !== null" size="sm">{{ count }}</gl-badge>
    </template>

    <template #actions>
      <gl-badge
        v-if="!open && newMergeRequests.length"
        :variant="activeList ? 'success' : 'muted'"
        class="gl-font-bold"
      >
        {{ newMergeRequestsBadgeText }}
      </gl-badge>
      <gl-button
        v-gl-tooltip
        :title="helpContent"
        icon="information-o"
        variant="link"
        class="gl-mr-2 gl-self-center"
      />
    </template>

    <template v-if="!hasMergeRequests && !loading" #empty>
      <p class="gl-pt-1 gl-text-center gl-text-subtle">
        {{ __('No merge requests match this list.') }}
      </p>
    </template>

    <template #default>
      <div class="gl-contents" data-testid="section-content">
        <slot></slot>
      </div>
    </template>

    <template v-if="open" #pagination>
      <slot name="pagination"></slot>
    </template>
  </crud-component>
</template>
