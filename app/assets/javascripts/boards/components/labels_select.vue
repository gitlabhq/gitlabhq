<script>
  /* global ListLabel */

  import LabelsSelect from '~/labels_select';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';

  export default {
    components: {
      loadingIcon,
    },
    props: {
      board: {
        type: Object,
        required: true,
      },
      labelsPath: {
        type: String,
        required: true,
      },
      canEdit: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    computed: {
      labelIds() {
        return this.board.labels.map(label => label.id);
      },
      isEmpty() {
        return this.board.labels.length === 0;
      },
    },
    mounted() {
      this.labelsDropdown = new LabelsSelect(this.$refs.dropdownButton, {
        handleClick: this.handleClick,
      });
    },
    methods: {
      labelStyle(label) {
        return {
          color: label.textColor,
          backgroundColor: label.color,
        };
      },
      handleClick(label) {
        if (label.isAny) {
          this.board.labels = [];
        } else if (!this.board.labels.find(l => l.id === label.id)) {
          this.board.labels.push(new ListLabel({
            id: label.id,
            title: label.title,
            color: label.color[0],
            textColor: label.text_color,
          }));
        } else {
          let labels = this.board.labels;
          labels = labels.filter(selected => selected.id !== label.id);
          this.board.labels = labels;
        }
      },
    },
  };
</script>

<template>
  <div class="block labels">
    <div class="title append-bottom-10">
      Labels
      <button
        v-if="canEdit"
        type="button"
        class="edit-link btn btn-blank pull-right"
      >
        Edit
      </button>
    </div>
    <div class="value issuable-show-labels">
      <span
        v-if="isEmpty"
        class="text-secondary"
      >
        Any Label
      </span>
      <a
        v-else
        href="#"
        v-for="label in board.labels"
        :key="label.id"
      >
        <span
          class="label color-label"
          :style="labelStyle(label)"
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
      />
      <div class="dropdown">
        <button
          ref="dropdownButton"
          :data-labels="labelsPath"
          class="dropdown-menu-toggle wide js-label-select
js-multiselect js-extra-options js-board-config-modal"
          data-field-name="label_id[]"
          :data-show-any="true"
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
          >
          </i>
        </button>
        <div
          class="dropdown-menu dropdown-select
dropdown-menu-paging dropdown-menu-labels dropdown-menu-selectable"
        >
          <div class="dropdown-input">
            <input
              autocomplete="off"
              class="dropdown-input-field"
              placeholder="Search"
              type="search"
            />
            <i
              aria-hidden="true"
              class="fa fa-search dropdown-input-search"
              data-hidden="true"
            >
            </i>
            <i
              aria-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
              data-hidden="true"
              role="button"
            >
            </i>
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
