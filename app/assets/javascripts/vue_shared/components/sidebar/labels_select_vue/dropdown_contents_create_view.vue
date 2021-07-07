<script>
import { GlTooltipDirective, GlButton, GlFormInput, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

export default {
  components: {
    GlButton,
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
      return Object.keys(colorsMap).map((color) => ({ [color]: colorsMap[color] }));
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
  <div class="labels-select-contents-create js-labels-create">
    <div class="dropdown-title d-flex align-items-center pt-0 pb-2">
      <gl-button
        :aria-label="__('Go back')"
        variant="link"
        size="small"
        class="js-btn-back dropdown-header-button p-0"
        icon="arrow-left"
        @click="toggleDropdownContentsCreateView"
      />
      <span class="flex-grow-1">{{ labelsCreateTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button p-0"
        icon="close"
        @click="toggleDropdownContents"
      />
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
      <div class="color-input-container gl-display-flex">
        <span
          class="dropdown-label-color-preview position-relative position-relative d-inline-block"
          :style="{ backgroundColor: selectedColor }"
        ></span>
        <gl-form-input
          v-model.trim="selectedColor"
          class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
          :placeholder="__('Use custom color #FF0000')"
        />
      </div>
    </div>
    <div class="dropdown-actions clearfix pt-2 px-2">
      <gl-button
        :disabled="disableCreate"
        category="primary"
        variant="success"
        class="float-left d-flex align-items-center"
        @click="handleCreateClick"
      >
        <gl-loading-icon v-show="labelCreateInProgress" size="sm" :inline="true" class="mr-1" />
        {{ __('Create') }}
      </gl-button>
      <gl-button class="float-right js-btn-cancel-create" @click="toggleDropdownContentsCreateView">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
