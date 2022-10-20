<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    unassigned: __('Unassigned'),
  },
  components: { GlButton, GlLoadingIcon },
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
      class="gl-display-flex gl-align-items-center gl-line-height-20 gl-text-gray-900 gl-font-weight-bold"
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
        class="gl-ml-2 hide-collapsed"
      />
      <gl-loading-icon
        v-if="loading && isClassicSidebar"
        size="sm"
        inline
        class="gl-mx-auto gl-my-0 hide-expanded"
      />
      <slot name="collapsed-right"></slot>
      <gl-button
        v-if="canUpdate && !initialLoading && canEdit"
        :id="buttonId"
        category="tertiary"
        size="small"
        class="gl-text-gray-900! gl-ml-auto hide-collapsed gl-mr-n2 shortcut-sidebar-dropdown-toggle"
        data-testid="edit-button"
        :data-track-action="tracking.event"
        :data-track-label="tracking.label"
        :data-track-property="tracking.property"
        data-qa-selector="edit_link"
        @keyup.esc="toggle"
        @click="toggle"
      >
        {{ editButtonText }}
      </gl-button>
    </div>
    <template v-if="!initialLoading">
      <div v-show="!edit" data-testid="collapsed-content" class="gl-line-height-14">
        <slot name="collapsed">{{ __('None') }}</slot>
      </div>
      <div v-show="edit" data-testid="expanded-content" :class="{ 'gl-mt-3': !isClassicSidebar }">
        <slot :edit="edit" :toggle="toggle"></slot>
      </div>
    </template>
  </div>
</template>
