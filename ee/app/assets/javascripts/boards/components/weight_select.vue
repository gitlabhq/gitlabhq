<script>
  /* eslint-disable vue/require-default-prop */

  import WeightSelect from 'ee/weight_select';

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
    computed: {
      valueClass() {
        if (this.valueText === ANY_WEIGHT) {
          return 'text-secondary';
        }
        return 'bold';
      },
      valueText() {
        if (this.value > 0) return this.value;
        if (this.value === 0) return NO_WEIGHT;
        return ANY_WEIGHT;
      },
    },
    mounted() {
      this.weightDropdown = new WeightSelect(this.$refs.dropdownButton, {
        handleClick: this.selectWeight,
        selected: this.value,
        fieldName: this.fieldName,
      });
    },
    methods: {
      selectWeight(weight) {
        this.board.weight = this.weightInt(weight);
      },
      weightInt(weight) {
        if (weight > 0) {
          return weight;
        }
        if (weight === NO_WEIGHT) {
          return 0;
        }
        return -1;
      },
    },
  };
</script>

<template>
  <div class="block weight">
    <div class="title append-bottom-10">
      Weight
      <button
        v-if="canEdit"
        type="button"
        class="edit-link btn btn-blank float-right"
      >
        Edit
      </button>
    </div>
    <div
      :class="valueClass"
      class="value"
    >
      {{ valueText }}
    </div>
    <div
      class="selectbox"
      style="display: none;"
    >
      <input
        :name="fieldName"
        type="hidden"
      />
      <div class="dropdown">
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
          >
          </i>
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-selectable dropdown-menu-weight">
          <div class="dropdown-content ">
            <ul>
              <li
                v-for="weight in weights"
                :key="weight"
              >
                <a
                  :class="{'is-active': weight == valueText}"
                  :data-id="weight"
                  href="#"
                >
                  {{ weight }}
                </a>
              </li>
            </ul>
          </div>
          <div class="dropdown-loading">
            <gl-loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
