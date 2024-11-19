<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    unassigned: __('Unassigned'),
  },
  components: { GlButton, GlLoadingIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    canUpdate: {},
    isClassicSidebar: {
      default: false,
    },
  },
  props: {
    buttonId: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDirty: {
      type: Boolean,
      required: false,
      default: false,
    },
    tracking: {
      type: Object,
      required: false,
      default: () => ({
        event: null,
        label: null,
        property: null,
      }),
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: true,
    },
    shouldShowConfirmationPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    editTooltip: {
      type: String,
      required: false,
      default: '',
    },
    editAriaLabel: {
      type: String,
      required: false,
      default: '',
    },
    editKeyshortcuts: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      edit: false,
    };
  },
  computed: {
    editButtonText() {
      return this.isDirty ? __('Apply') : __('Edit');
    },
    editTooltipText() {
      return this.isDirty ? '' : this.editTooltip;
    },
    editAriaLabelText() {
      return this.isDirty ? this.editButtonText : this.editAriaLabel;
    },
    editKeyshortcutsText() {
      return this.isDirty ? __('Escape') : this.editKeyshortcuts;
    },
  },
  destroyed() {
    window.removeEventListener('click', this.collapseWhenOffClick);
    window.removeEventListener('keyup', this.collapseOnEscape);
  },
  methods: {
    collapseWhenOffClick({ target }) {
      if (!this.$el.contains(target)) {
        this.collapse();
      }
    },
    collapseOnEscape({ key }) {
      if (key === 'Escape') {
        this.collapse();
      }
    },
    expand() {
      if (this.edit) {
        return;
      }

      if (this.canEdit && this.canUpdate) {
        this.edit = true;
      }
      this.$emit('open');
      window.addEventListener('click', this.collapseWhenOffClick);
      window.addEventListener('keyup', this.collapseOnEscape);
    },
    collapse({ emitEvent = true } = {}) {
      if (!this.edit) {
        return;
      }

      this.edit = false;
      if (emitEvent) {
        this.$emit('close');
      }
      window.removeEventListener('click', this.collapseWhenOffClick);
      window.removeEventListener('keyup', this.collapseOnEscape);
    },
    toggle({ emitEvent = true } = {}) {
      if (this.shouldShowConfirmationPopover) {
        this.$emit('edit-confirm');
        return;
      }

      if (this.edit) {
        this.collapse({ emitEvent });
      } else {
        this.expand();
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-flex gl-items-center gl-font-bold gl-leading-20 gl-text-default"
      @click.self="collapse"
    >
      <span class="hide-collapsed" data-testid="title" @click="collapse">
        {{ title }}
      </span>
      <slot name="title-extra"></slot>
      <gl-loading-icon
        v-if="loading || initialLoading"
        size="sm"
        inline
        class="hide-collapsed gl-ml-2"
      />
      <gl-loading-icon
        v-if="loading && isClassicSidebar"
        size="sm"
        inline
        class="hide-expanded gl-mx-auto gl-my-0"
      />
      <slot name="collapsed-right"></slot>
      <gl-button
        v-if="canUpdate && !initialLoading && canEdit"
        :id="buttonId"
        v-gl-tooltip.viewport.html
        category="tertiary"
        size="small"
        class="hide-collapsed shortcut-sidebar-dropdown-toggle -gl-mr-2 gl-ml-auto"
        :title="editTooltipText"
        :aria-label="editAriaLabelText"
        :aria-keyshortcuts="editKeyshortcutsText"
        data-testid="edit-button"
        :data-track-action="tracking.event"
        :data-track-label="tracking.label"
        :data-track-property="tracking.property"
        @keyup.esc="toggle"
        @click="toggle"
      >
        {{ editButtonText }}
      </gl-button>
    </div>
    <template v-if="!initialLoading">
      <div v-show="!edit" data-testid="collapsed-content">
        <slot name="collapsed">{{ __('None') }}</slot>
      </div>
      <div v-show="edit" data-testid="expanded-content" :class="{ 'gl-mt-3': !isClassicSidebar }">
        <slot :edit="edit" :toggle="toggle"></slot>
      </div>
    </template>
  </div>
</template>
