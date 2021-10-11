<script>
import { GlButton, GlDropdown, GlDropdownItem, GlLink } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';
import { isDropdownVariantStandalone, isDropdownVariantSidebar } from './utils';

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
    issuableType: {
      type: String,
      required: true,
    },
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showDropdownContentsCreateView: false,
      localSelectedLabels: [...this.selectedLabels],
      isDirty: false,
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
    buttonText() {
      if (!this.localSelectedLabels.length) {
        return this.dropdownButtonText || __('Label');
      } else if (this.localSelectedLabels.length > 1) {
        return sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
          firstLabelName: this.localSelectedLabels[0].title,
          remainingLabelCount: this.localSelectedLabels.length - 1,
        });
      }
      return this.localSelectedLabels[0].title;
    },
    showDropdownFooter() {
      return !this.showDropdownContentsCreateView && !this.isStandalone;
    },
    isStandalone() {
      return isDropdownVariantStandalone(this.variant);
    },
  },
  watch: {
    localSelectedLabels: {
      handler() {
        this.isDirty = true;
      },
      deep: true,
    },
    isVisible(newVal) {
      if (newVal) {
        this.$refs.dropdown.show();
        this.isDirty = false;
      } else {
        this.$refs.dropdown.hide();
        this.setLabels();
      }
    },
    selectedLabels(newVal) {
      this.localSelectedLabels = newVal;
    },
  },
  methods: {
    toggleDropdownContentsCreateView() {
      this.showDropdownContentsCreateView = !this.showDropdownContentsCreateView;
    },
    toggleDropdownContent() {
      this.toggleDropdownContentsCreateView();
      // Required to recalculate dropdown position as its size changes
      if (this.$refs.dropdown?.$refs.dropdown) {
        this.$refs.dropdown.$refs.dropdown.$_popper.scheduleUpdate();
      }
    },
    setLabels() {
      if (!this.isDirty) {
        return;
      }
      this.$emit('setLabels', this.localSelectedLabels);
    },
    handleDropdownHide() {
      if (!isDropdownVariantSidebar(this.variant)) {
        this.setLabels();
      }
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    :text="buttonText"
    class="gl-w-full gl-mt-2"
    data-qa-selector="labels_dropdown_content"
    @hide="handleDropdownHide"
  >
    <template #header>
      <div
        v-if="!isStandalone"
        class="dropdown-title gl-display-flex gl-align-items-center gl-pt-0 gl-pb-3!"
        data-testid="dropdown-header"
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
          data-testid="close-button"
          @click="$emit('closeDropdown')"
        />
      </div>
    </template>
    <template #default>
      <component
        :is="dropdownContentsView"
        v-model="localSelectedLabels"
        :selected-labels="selectedLabels"
        :allow-multiselect="allowMultiselect"
        :issuable-type="issuableType"
        @hideCreateView="toggleDropdownContentsCreateView"
      />
    </template>
    <template #footer>
      <div v-if="showDropdownFooter" data-testid="dropdown-footer">
        <gl-dropdown-item
          v-if="allowLabelCreate"
          data-testid="create-label-button"
          @click.capture.native.stop="toggleDropdownContent"
        >
          {{ footerCreateLabelTitle }}
        </gl-dropdown-item>
        <gl-dropdown-item :href="labelsManagePath" @click.capture.native.stop>
          {{ footerManageLabelTitle }}
        </gl-dropdown-item>
      </div>
    </template>
  </gl-dropdown>
</template>
