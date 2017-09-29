<template>
    <div class="block labels">
    <div class="title append-bottom-10">
      Labels
      <i aria-hidden="true" class="fa fa-spinner fa-spin block-loading" data-hidden="true" style="display: none;"></i>
      <a
        v-if="canEdit"
        class="edit-link pull-right"
        href="#"
      >
        Edit
      </a>
    </div>
    <div class="value issuable-show-labels">
      <span v-if="board.labels.length === 0" class="no-value">
        Any label
      </span>
      <a
        href="#"
        v-for="label in board.labels"
        :key="label.id"
      >
        <span
          class="label color-label has-tooltip"
          :style="`background-color: ${label.color}; color: ${label.textColor};`"
          title=""
        >
          {{ label.title }}
        </span>
      </a>
    </div>
    <div class="selectbox" style="display: none">

      <div class="dropdown">
        <button
          class="dropdown-menu-toggle wide js-label-select js-multiselect js-board-config-modal"
          data-field-name="issue[label_names][]"
          v-bind:data-labels="labelsPath"
          data-toggle="dropdown"
          type="button"
        >
          <span class="dropdown-toggle-text">
            Label
          </span> <i aria-hidden="true" class="fa fa-chevron-down" data-hidden="true"></i>
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-paging dropdown-menu-labels dropdown-menu-selectable">
          <div class="dropdown-input">
            <input
              autocomplete="off"
              class="dropdown-input-field" id=""
              placeholder="Search"
              type="search"
              value=""
            >
            <i aria-hidden="true" class="fa fa-search dropdown-input-search" data-hidden="true"></i>
            <i aria-hidden="true" class="fa fa-times dropdown-input-clear js-dropdown-input-clear" data-hidden="true" role="button"></i>
          </div>
          <div class="dropdown-content"></div>
          <div class="dropdown-loading">
            <i aria-hidden="true" class="fa fa-spinner fa-spin" data-hidden="true"></i>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

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
  },
  components: {
    loadingIcon,
  },
  data() {
    return {
      isOpen: false,
      loading: true,
    };
  },
  mounted() {
    new LabelsSelect();
  },
  methods: {
    open() {
      this.isOpen = true;
    },
    close() {
      this.isOpen = false;
    },
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
};
</script>
