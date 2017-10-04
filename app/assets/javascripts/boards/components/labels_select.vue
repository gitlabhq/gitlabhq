<script>
/* global LabelsSelect */

import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import eventHub from '../eventhub';

export default {
  props: {
    board: {
      type: Object,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    value: {
      type: Array,
      required: false,
    },
    defaultText: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: Array,
      required: true,
    },
  },
  components: {
    loadingIcon,
  },
  computed: {
    labelIds() {
      return this.selected.map(label => label.id).join(',');
    },
  },
  mounted() {
    new LabelsSelect();
  },
};
</script>

<template>
  <div class="block labels">
    <div class="title append-bottom-10">
      Labels
      <a
        v-if="canEdit"
        class="edit-link pull-right"
        href="#"
      >
        Edit
      </a>
    </div>
    <div class="value issuable-show-labels">
      <span
        v-if="board.labels.length === 0"
        class="text-secondary"
      >
        Any label
      </span>
      <a
        href="#"
        v-for="label in board.labels"
        :key="label.id"
      >
        <span
          class="label color-label has-tooltip"
          :style="`
            background-color: ${label.color};
            color: ${label.textColor};
          `"
          title=""
        >
          {{ label.title }}
        </span>
      </a>
    </div>
    <div
      class="selectbox"
      style="display: none"
    >
      <input
        type="hidden"
        name="label_id[]"
        v-for="labelId in labelIds"
        :key="labelId"
        :value="labelId"
      >
      <div class="dropdown">
        <button
          v-bind:data-labels="labelsPath"
          class="dropdown-menu-toggle wide js-label-select js-multiselect js-board-config-modal"
          data-field-name="label_id[]"
          data-toggle="dropdown"
          type="button"
        >
          <span class="dropdown-toggle-text">
            Label
          </span>
          <i
            aria-hidden="true"
            class="fa fa-chevron-down"
            data-hidden="true"
          />
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-paging dropdown-menu-labels dropdown-menu-selectable">
          <div class="dropdown-input">
            <input
              autocomplete="off"
              class="dropdown-input-field"
              placeholder="Search"
              type="search"
            >
            <i
              aria-hidden="true"
              class="fa fa-search dropdown-input-search"
              data-hidden="true"
            />
            <i
              aria-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
              data-hidden="true"
              role="button"
            />
          </div>
          <div class="dropdown-content"></div>
          <div class="dropdown-loading">
            <loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
