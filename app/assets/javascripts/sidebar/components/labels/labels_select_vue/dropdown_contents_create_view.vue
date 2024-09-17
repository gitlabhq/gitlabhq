<script>
import { GlTooltipDirective, GlButton, GlFormInput, GlLink, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue` instead.
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
  <div class="labels-select-contents-create">
    <div class="dropdown-title pt-0 pb-2 gl-mb-0 gl-flex gl-items-center">
      <gl-button
        :aria-label="__('Go back')"
        category="tertiary"
        size="small"
        class="js-btn-back dropdown-header-button p-0"
        icon="arrow-left"
        @click="toggleDropdownContentsCreateView"
      />
      <span class="flex-grow-1">{{ labelsCreateTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        category="tertiary"
        size="small"
        class="dropdown-header-button p-0"
        icon="close"
        @click="toggleDropdownContents"
      />
    </div>
    <div class="dropdown-input">
      <gl-form-input
        v-model.trim="labelTitle"
        :placeholder="__('Label name')"
        :autofocus="true"
        data-testid="label-title"
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
      <div class="color-input-container gl-flex">
        <gl-form-input
          v-model.trim="selectedColor"
          class="-gl-mr-1 gl-mb-2 gl-w-8 gl-rounded-br-none gl-rounded-tr-none"
          type="color"
          :value="selectedColor"
          :placeholder="__('Open color picker')"
          data-testid="selected-color"
        />
        <gl-form-input
          v-model.trim="selectedColor"
          class="gl-mb-2 gl-rounded-bl-none gl-rounded-tl-none"
          :placeholder="__('Use custom color #FF0000')"
        />
      </div>
    </div>
    <div class="dropdown-actions clearfix pt-2 px-2">
      <gl-button
        :disabled="disableCreate"
        category="primary"
        variant="confirm"
        class="float-left gl-flex gl-items-center"
        data-testid="create-click"
        @click="handleCreateClick"
      >
        <gl-loading-icon v-show="labelCreateInProgress" size="sm" :inline="true" class="mr-1" />
        {{ __('Create') }}
      </gl-button>
      <gl-button
        class="js-btn-cancel-create gl-float-right"
        @click="toggleDropdownContentsCreateView"
      >
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
