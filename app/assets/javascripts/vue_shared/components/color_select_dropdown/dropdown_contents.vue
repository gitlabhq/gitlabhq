<script>
import { GlDropdown } from '@gitlab/ui';
import ColorItem from './color_item.vue';
import DropdownContentsColorView from './dropdown_contents_color_view.vue';
import DropdownHeader from './dropdown_header.vue';
import { isDropdownVariantSidebar } from './utils';

export default {
  components: {
    ColorItem,
    DropdownContentsColorView,
    DropdownHeader,
    GlDropdown,
  },
  props: {
    dropdownTitle: {
      type: String,
      required: true,
    },
    selectedColor: {
      type: Object,
      required: true,
    },
    dropdownButtonText: {
      type: String,
      required: true,
    },
    variant: {
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
      localSelectedColor: this.selectedColor,
      isDirty: false,
    };
  },
  computed: {
    buttonText() {
      if (!this.hasSelectedColor) {
        return this.dropdownButtonText;
      }

      return this.localSelectedColor.title;
    },
    hasSelectedColor() {
      return this.localSelectedColor?.title;
    },
  },
  watch: {
    localSelectedColor: {
      handler() {
        this.isDirty = true;
      },
      deep: true,
    },
    isVisible(newVal) {
      if (newVal) {
        this.$refs.dropdown.show();
        this.isDirty = false;
        this.localSelectedColor = this.selectedColor;
      } else {
        this.$refs.dropdown.hide();
        this.setColor();
      }
    },
    selectedColor(newVal) {
      if (!this.isDirty) {
        this.localSelectedColor = newVal;
      }
    },
  },
  methods: {
    setColor() {
      if (!this.isDirty) {
        return;
      }
      this.$emit('setColor', this.localSelectedColor);
    },
    handleDropdownHide() {
      this.$emit('closeDropdown');
      if (!isDropdownVariantSidebar(this.variant)) {
        this.setColor();
      }
      this.$refs.dropdown.hide();
    },
  },
};
</script>

<template>
  <gl-dropdown ref="dropdown" class="gl-w-full" @hide="handleDropdownHide">
    <template #button-text>
      <color-item
        v-if="hasSelectedColor"
        :color="localSelectedColor.color"
        :title="localSelectedColor.title"
      />
      <span v-else data-testid="fallback-button-text">{{ buttonText }}</span>
    </template>
    <template #header>
      <dropdown-header
        ref="header"
        :dropdown-title="dropdownTitle"
        @closeDropdown="handleDropdownHide"
      />
    </template>
    <template #default>
      <dropdown-contents-color-view
        v-model="localSelectedColor"
        @closeDropdown="handleDropdownHide"
      />
    </template>
  </gl-dropdown>
</template>
