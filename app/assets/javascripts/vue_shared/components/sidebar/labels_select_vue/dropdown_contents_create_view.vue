<script>
import { mapState, mapActions } from 'vuex';
import {
  GlTooltipDirective,
  GlButton,
  GlIcon,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
} from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      labelTitle: '',
      selectedColor: '',
    };
  },
  computed: {
    ...mapState(['labelsCreateTitle', 'labelCreateInProgress']),
    disableCreate() {
      return !this.labelTitle.length || !this.selectedColor.length || this.labelCreateInProgress;
    },
    suggestedColors() {
      const colorsMap = gon.suggested_label_colors;
      return Object.keys(colorsMap).map(color => ({ [color]: colorsMap[color] }));
    },
  },
  methods: {
    ...mapActions(['toggleDropdownContents', 'toggleDropdownContentsCreateView', 'createLabel']),
    getColorCode(color) {
      return Object.keys(color).pop();
    },
    getColorName(color) {
      return Object.values(color).pop();
    },
    handleColorClick(color) {
      this.selectedColor = this.getColorCode(color);
    },
    handleCreateClick() {
      this.createLabel({
        title: this.labelTitle,
        color: this.selectedColor,
      });
    },
  },
};
</script>

<template>
  <div class="labels-select-contents-create">
    <div class="dropdown-title d-flex align-items-center pt-0 pb-2">
      <gl-button
        :aria-label="__('Go back')"
        variant="link"
        size="sm"
        class="dropdown-header-button p-0"
        @click="toggleDropdownContentsCreateView"
      >
        <gl-icon name="arrow-left" />
      </gl-button>
      <span class="flex-grow-1">{{ labelsCreateTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="sm"
        class="dropdown-header-button p-0"
        @click="toggleDropdownContents"
      >
        <gl-icon name="close" />
      </gl-button>
    </div>
    <div class="dropdown-input">
      <gl-form-input
        v-model.trim="labelTitle"
        :placeholder="__('Name new label')"
        :autofocus="true"
      />
    </div>
    <div class="dropdown-content px-2">
      <div class="suggest-colors suggest-colors-dropdown mt-0 mb-2">
        <gl-link
          v-for="(color, index) in suggestedColors"
          :key="index"
          v-gl-tooltip:tooltipcontainer
          :style="{ backgroundColor: getColorCode(color) }"
          :title="getColorName(color)"
          @click.prevent="handleColorClick(color)"
        />
      </div>
      <div class="color-input-container d-flex">
        <span
          class="dropdown-label-color-preview position-relative position-relative d-inline-block"
          :style="{ backgroundColor: selectedColor }"
        ></span>
        <gl-form-input v-model.trim="selectedColor" :placeholder="__('Use custom color #FF0000')" />
      </div>
    </div>
    <div class="dropdown-actions clearfix pt-2 px-2">
      <gl-button
        :disabled="disableCreate"
        variant="primary"
        class="pull-left d-flex align-items-center"
        @click="handleCreateClick"
      >
        <gl-loading-icon v-show="labelCreateInProgress" :inline="true" class="mr-1" />
        {{ __('Create') }}
      </gl-button>
      <gl-button class="pull-right" @click="toggleDropdownContentsCreateView">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
