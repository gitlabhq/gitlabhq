<script>
/* global BoardService, WeightSelect */

import '~/weight_select';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import eventHub from '../eventhub';

export default {
  props: {
    board: {
      type: Object,
      required: true,
    },
    value: {
      type: [Number, String],
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
    weights: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      fieldName: 'weight',
    };
  },
  components: {
    loadingIcon,
  },
  computed: {
    valueClass() {
      if (this.value === 'Any Weight') {
        return 'placeholder';
      }
      return 'bold';
    },
  },
  methods: {
    selectWeight(weight) {
      this.$set(this.board, 'weight', weight);
    },
  },
  mounted() {
    new WeightSelect(this.$refs.dropdownButton, {
      handleClick: this.selectWeight,
      selected: this.value,
      fieldName: this.fieldName,
    });
  }
};
</script>

<template>
  <div class="block weight">
    <div class="title append-bottom-10">
      {{ title }}
      <a
        v-if="canEdit"
        class="edit-link pull-right"
        href="#"
      >
        Edit
      </a>
    </div>
    <div
      class="value"
      :class="valueClass"
    >
      {{ value }}
    </div>
    <div
      class="selectbox"
      style="display: none;"
    >
      <input
        type="hidden"
        :name="this.fieldName"
      />
      <div class="dropdown ">
        <button
          ref="dropdownButton"
          class="dropdown-menu-toggle js-weight-select wide"
          type="button"
          data-default-label="Weight"
          data-toggle="dropdown"
        >
          <span class="dropdown-toggle-text is-default">
            Weight
          </span>
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-chevron-down"
          />
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-selectable dropdown-menu-weight">
          <div class="dropdown-content ">
            <ul>
              <li
                v-for="weight in weights"
                :key="weight"
              >
                <a
                  :data-id="weight"
                  href="#"
                >
                  {{ weight }}
                </a>
              </li>
            </ul>
          </div>
          <div class="dropdown-loading">
            <loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
