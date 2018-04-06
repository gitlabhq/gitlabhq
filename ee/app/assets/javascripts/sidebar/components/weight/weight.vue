<script>
  /* eslint-disable vue/require-default-prop */

  import $ from 'jquery';
  import { s__ } from '~/locale';
  import eventHub from '~/sidebar/event_hub';
  import icon from '~/vue_shared/components/icon.vue';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';

  export default {
    components: {
      icon,
      loadingIcon,
    },
    props: {
      fetching: {
        type: Boolean,
        required: false,
        default: false,
      },
      loading: {
        type: Boolean,
        required: false,
        default: false,
      },
      weight: {
        type: Number,
        required: false,
      },
      weightOptions: {
        type: Array,
        required: true,
      },
      weightNoneValue: {
        type: String,
        required: true,
      },
      editable: {
        type: Boolean,
        required: false,
        default: false,
      },
      id: {
        type: Number,
        required: false,
      },
    },
    data() {
      return {
        shouldShowDropdown: false,
        collapseAfterDropdownCloses: false,
      };
    },
    computed: {
      isNoValue() {
        return this.checkIfNoValue(this.weight);
      },
      collapsedWeightLabel() {
        let label = this.weight;
        if (this.checkIfNoValue(this.weight)) {
          label = s__('Sidebar|No');
        }

        return label;
      },
      noValueLabel() {
        return s__('Sidebar|None');
      },
      changeWeightLabel() {
        return s__('Sidebar|Change weight');
      },
      dropdownToggleLabel() {
        let label = this.weight;
        if (this.checkIfNoValue(this.weight)) {
          label = s__('Sidebar|Weight');
        }

        return label;
      },
      shouldShowWeight() {
        return !this.fetching && !this.shouldShowDropdown;
      },
    },
    mounted() {
      $(this.$refs.weightDropdown).glDropdown({
        showMenuAbove: false,
        selectable: true,
        filterable: false,
        multiSelect: false,
        data: (searchTerm, callback) => {
          callback(this.weightOptions);
        },
        renderRow: (weight) => {
          const isActive = weight === this.weight ||
            (this.checkIfNoValue(weight) && this.checkIfNoValue(this.weight));

          return `
            <li>
              <a href="#" class="${isActive ? 'is-active' : ''}">
                ${weight}
              </a>
            </li>
          `;
        },
        hidden: () => {
          this.shouldShowDropdown = false;
          this.collapseAfterDropdownCloses = false;
        },
        clicked: (options) => {
          const selectedValue = this.checkIfNoValue(options.selectedObj) ?
            null :
            options.selectedObj;
          const resultantValue = options.isMarking ? selectedValue : null;
          eventHub.$emit('updateWeight', resultantValue, this.id);
        },
      });
    },
    methods: {
      checkIfNoValue(weight) {
        return weight === undefined ||
          weight === null ||
          weight === 0 ||
          weight === this.weightNoneValue;
      },
      showDropdown() {
        this.shouldShowDropdown = true;
        // Trigger the bootstrap dropdown
        setTimeout(() => {
          $(this.$refs.dropdownToggle).dropdown('toggle');
        });
      },
      onCollapsedClick() {
        this.collapseAfterDropdownCloses = true;
        this.showDropdown();
      },
    },
  };
</script>

<template>
  <div
    class="block weight"
    :class="{ 'collapse-after-update': collapseAfterDropdownCloses }"
  >
    <div
      class="sidebar-collapsed-icon js-weight-collapsed-block"
      @click="onCollapsedClick"
    >
      <icon
        name="scale"
        :size="16"
      />
      <loading-icon
        v-if="fetching"
        class="js-weight-collapsed-loading-icon"
      />
      <span
        v-else
        class="js-weight-collapsed-weight-label"
      >
        {{ collapsedWeightLabel }}
      </span>
    </div>
    <div class="title hide-collapsed">
      {{ s__('Sidebar|Weight') }}
      <loading-icon
        v-if="fetching || loading"
        :inline="true"
        class="js-weight-loading-icon"
      />
      <a
        v-if="editable"
        class="pull-right js-weight-edit-link"
        href="#"
        @click="showDropdown"
      >
        {{ __('Edit') }}
      </a>
    </div>
    <div
      v-if="shouldShowWeight"
      class="value hide-collapsed js-weight-weight-label"
    >
      <strong v-if="!isNoValue">
        {{ weight }}
      </strong>
      <span
        v-else
        class="no-value">
        {{ noValueLabel }}
      </span>
    </div>

    <div
      class="selectbox hide-collapsed"
      :class="{ show: shouldShowDropdown }"
    >
      <div
        ref="weightDropdown"
        class="dropdown"
      >
        <button
          ref="dropdownToggle"
          class="dropdown-menu-toggle js-gl-dropdown-refresh-on-open"
          type="button"
          data-toggle="dropdown"
        >
          <span
            class="dropdown-toggle-text js-weight-dropdown-toggle-text"
            :class="{ 'is-default': isNoValue }"
          >
            {{ dropdownToggleLabel }}
          </span>
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-chevron-down"
          >
          </i>
        </button>
        <div
          v-once
          class="dropdown-menu dropdown-select dropdown-menu-selectable dropdown-menu-weight"
        >
          <div class="dropdown-title">
            <span>
              {{ changeWeightLabel }}
            </span>
            <button
              class="dropdown-title-button dropdown-menu-close"
              aria-label="Close"
              type="button"
            >
              <i
                aria-hidden="true"
                data-hidden="true"
                class="fa fa-times dropdown-menu-close-icon"
              >
              </i>
            </button>
          </div>
          <div class="dropdown-content js-weight-dropdown-content"></div>
        </div>
      </div>
    </div>
  </div>
</template>
