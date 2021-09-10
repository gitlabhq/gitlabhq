<script>
import { GlButton, GlDropdown, GlDropdownItem, GlLink } from '@gitlab/ui';

import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';
import { isDropdownVariantSidebar, isDropdownVariantEmbedded } from './utils';

export default {
  components: {
    DropdownContentsLabelsView,
    DropdownContentsCreateView,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlLink,
  },
  inject: ['allowLabelCreate', 'labelsManagePath'],
  props: {
    labelsCreateTitle: {
      type: String,
      required: true,
    },
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowMultiselect: {
      type: Boolean,
      required: true,
    },
    labelsListTitle: {
      type: String,
      required: true,
    },
    dropdownButtonText: {
      type: String,
      required: true,
    },
    footerCreateLabelTitle: {
      type: String,
      required: true,
    },
    footerManageLabelTitle: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showDropdownContentsCreateView: false,
    };
  },
  computed: {
    dropdownContentsView() {
      if (this.showDropdownContentsCreateView) {
        return 'dropdown-contents-create-view';
      }
      return 'dropdown-contents-labels-view';
    },
    dropdownTitle() {
      return this.showDropdownContentsCreateView ? this.labelsCreateTitle : this.labelsListTitle;
    },
    showDropdownFooter() {
      return (
        !this.showDropdownContentsCreateView &&
        (this.isDropdownVariantSidebar(this.variant) ||
          this.isDropdownVariantEmbedded(this.variant))
      );
    },
  },
  methods: {
    showDropdown() {
      this.$refs.dropdown.show();
    },
    toggleDropdownContentsCreateView() {
      this.showDropdownContentsCreateView = !this.showDropdownContentsCreateView;
    },
    toggleDropdownContent() {
      this.toggleDropdownContentsCreateView();
      // Required to recalculate dropdown position as its size changes
      this.$refs.dropdown.$refs.dropdown.$_popper.scheduleUpdate();
    },
    isDropdownVariantSidebar,
    isDropdownVariantEmbedded,
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    :text="dropdownButtonText"
    class="gl-w-full gl-mt-2"
    data-qa-selector="labels_dropdown_content"
  >
    <template #header>
      <div
        v-if="isDropdownVariantSidebar(variant) || isDropdownVariantEmbedded(variant)"
        class="dropdown-title gl-display-flex gl-align-items-center gl-pt-0 gl-pb-3!"
      >
        <gl-button
          v-if="showDropdownContentsCreateView"
          :aria-label="__('Go back')"
          variant="link"
          size="small"
          class="js-btn-back dropdown-header-button gl-p-0"
          icon="arrow-left"
          data-testid="go-back-button"
          @click.stop="toggleDropdownContent"
        />
        <span class="gl-flex-grow-1">{{ dropdownTitle }}</span>
        <gl-button
          :aria-label="__('Close')"
          variant="link"
          size="small"
          class="dropdown-header-button gl-p-0!"
          icon="close"
          @click="$emit('closeDropdown')"
        />
      </div>
    </template>
    <component
      :is="dropdownContentsView"
      :selected-labels="selectedLabels"
      :allow-multiselect="allowMultiselect"
      @hideCreateView="toggleDropdownContentsCreateView"
      @setLabels="$emit('setLabels', $event)"
    />
    <template #footer>
      <div v-if="showDropdownFooter" data-testid="dropdown-footer">
        <gl-dropdown-item
          v-if="allowLabelCreate"
          data-testid="create-label-button"
          @click.native.capture.stop="toggleDropdownContent"
        >
          {{ footerCreateLabelTitle }}
        </gl-dropdown-item>
        <gl-dropdown-item :href="labelsManagePath" @click.native.capture.stop>
          {{ footerManageLabelTitle }}
        </gl-dropdown-item>
      </div>
    </template>
  </gl-dropdown>
</template>
