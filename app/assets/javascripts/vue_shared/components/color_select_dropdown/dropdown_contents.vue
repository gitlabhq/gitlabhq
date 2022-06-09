<script>
import { GlDropdown } from '@gitlab/ui';
import DropdownContentsColorView from './dropdown_contents_color_view.vue';
import DropdownHeader from './dropdown_header.vue';
import { isDropdownVariantSidebar } from './utils';

export default {
  components: {
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
      if (!this.localSelectedColor?.title) {
        return this.dropdownButtonText;
      }

      return this.localSelectedColor.title;
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
  <gl-dropdown ref="dropdown" :text="buttonText" class="gl-w-full" @hide="handleDropdownHide">
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
