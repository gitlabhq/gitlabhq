<script>
/* global BoardService, WeightSelect */

import '~/weight_select';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import eventHub from '../eventhub';

const ANY_WEIGHT = 'Any Weight';
const NO_WEIGHT = 'No Weight';

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
      if (this.valueText === ANY_WEIGHT) {
        return 'text-secondary';
      }
      return 'bold';
    },
    valueText() {
      if (this.value > 0) return this.value;
      if (this.value == 0) return NO_WEIGHT;
      return ANY_WEIGHT;
    }
  },
  methods: {
    selectWeight(weight) {
      if (weight === ANY_WEIGHT) {
        weight = -1;
      }
      if (weight === NO_WEIGHT) {
        weight = 0;
      }
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
      Weight
      <button
        v-if="canEdit"
        type="button"
        class="edit-link btn btn-blank pull-right"
      >
        Edit
      </button>
    </div>
    <div
      class="value"
      :class="valueClass"
    >
      {{ valueText }}
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
