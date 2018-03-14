<script>
import { __ } from '~/locale';

export default {
  props: {
    headerTitle: {
      type: String,
      required: false,
      default: () => __('Create new label'),
    },
  },
  created() {
    this.suggestedColors = gon.suggested_label_colors;
  },
};
</script>

<template>
  <div class="dropdown-page-two dropdown-new-label">
    <div class="dropdown-title">
      <button
        type="button"
        class="dropdown-title-button dropdown-menu-back"
        :aria-label="__('Go back')"
      >
        <i
          aria-hidden="true"
          class="fa fa-arrow-left"
          data-hidden="true"
        >
        </i>
      </button>
      {{ headerTitle }}
      <button
        type="button"
        class="dropdown-title-button dropdown-menu-close"
        :aria-label="__('Close')"
      >
        <i
          aria-hidden="true"
          class="fa fa-times dropdown-menu-close-icon"
          data-hidden="true"
        >
        </i>
      </button>
    </div>
    <div class="dropdown-content">
      <div class="dropdown-labels-error js-label-error"></div>
      <input
        id="new_label_name"
        type="text"
        class="default-dropdown-input"
        :placeholder="__('Name new label')"
      />
      <div class="suggest-colors suggest-colors-dropdown">
        <a
          v-for="(color, index) in suggestedColors"
          href="#"
          :key="index"
          :data-color="color"
          :style="{
            backgroundColor: color,
          }"
        >
          &nbsp;
        </a>
      </div>
      <div class="dropdown-label-color-input">
        <div class="dropdown-label-color-preview js-dropdown-label-color-preview"></div>
        <input
          id="new_label_color"
          type="text"
          class="default-dropdown-input"
          :placeholder="__('Assign custom color like #FF0000')"
        />
      </div>
      <div class="clearfix">
        <button
          type="button"
          class="btn btn-primary pull-left js-new-label-btn disabled"
        >
          {{ __('Create') }}
        </button>
        <button
          type="button"
          class="btn btn-default pull-right js-cancel-label-btn"
        >
          {{ __('Cancel') }}
        </button>
      </div>
    </div>
  </div>
</template>
