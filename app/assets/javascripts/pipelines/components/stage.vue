<script>
  import $ from 'jquery';

  /**
   * Renders each stage of the pipeline mini graph.
   *
   * Given the provided endpoint will make a request to
   * fetch the dropdown data when the stage is clicked.
   *
   * Request is made inside this component to make it reusable between:
   * 1. Pipelines main table
   * 2. Pipelines table in commit and Merge request views
   * 3. Merge request widget
   * 4. Commit widget
   */
  import axios from '../../lib/utils/axios_utils';
  import Flash from '../../flash';
  import Icon from '../../vue_shared/components/icon.vue';
  import LoadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    components: {
      LoadingIcon,
      Icon,
    },

    directives: {
      tooltip,
    },

    props: {
      stage: {
        type: Object,
        required: true,
      },

      updateDropdown: {
        type: Boolean,
        required: false,
        default: false,
      },
    },

    data() {
      return {
        isLoading: false,
        dropdownContent: '',
      };
    },

    computed: {
      dropdownClass() {
        return this.dropdownContent.length > 0 ? 'js-builds-dropdown-container' : 'js-builds-dropdown-loading';
      },

      triggerButtonClass() {
        return `ci-status-icon-${this.stage.status.group}`;
      },

      borderlessIcon() {
        return `${this.stage.status.icon}_borderless`;
      },
    },

    watch: {
      updateDropdown() {
        if (this.updateDropdown &&
          this.isDropdownOpen() &&
          !this.isLoading) {
          this.fetchJobs();
        }
      },
    },

    updated() {
      if (this.dropdownContent.length > 0) {
        this.stopDropdownClickPropagation();
      }
    },

    methods: {
      onClickStage() {
        if (!this.isDropdownOpen()) {
          this.isLoading = true;
          this.fetchJobs();
        }
      },

      fetchJobs() {
        axios.get(this.stage.dropdown_path)
          .then(({ data }) => {
            this.dropdownContent = data.html;
            this.isLoading = false;
          })
          .catch(() => {
            this.closeDropdown();
            this.isLoading = false;

            Flash('Something went wrong on our end.');
          });
      },

      /**
       * When the user right clicks or cmd/ctrl + click in the job name
       * the dropdown should not be closed and the link should open in another tab,
       * so we stop propagation of the click event inside the dropdown.
       *
       * Since this component is rendered multiple times per page we need to guarantee we only
       * target the click event of this component.
       */
      stopDropdownClickPropagation() {
        $(this.$el.querySelectorAll('.js-builds-dropdown-list a.mini-pipeline-graph-dropdown-item'))
          .on('click', (e) => {
            e.stopPropagation();
          });
      },

      closeDropdown() {
        if (this.isDropdownOpen()) {
          $(this.$refs.dropdown).dropdown('toggle');
        }
      },

      isDropdownOpen() {
        return this.$el.classList.contains('open');
      },
    },
  };
</script>

<template>
  <div class="dropdown">
    <button
      v-tooltip
      :class="triggerButtonClass"
      @click="onClickStage"
      class="mini-pipeline-graph-dropdown-toggle js-builds-dropdown-button"
      :title="stage.title"
      data-placement="top"
      data-toggle="dropdown"
      type="button"
      id="stageDropdown"
      aria-haspopup="true"
      aria-expanded="false"
    >

      <span
        aria-hidden="true"
        :aria-label="stage.title"
      >
        <icon :name="borderlessIcon" />
      </span>

      <i
        class="fa fa-caret-down"
        aria-hidden="true"
      >
      </i>
    </button>

    <ul
      class="dropdown-menu mini-pipeline-graph-dropdown-menu js-builds-dropdown-container"
      aria-labelledby="stageDropdown"
    >

      <li
        :class="dropdownClass"
        class="js-builds-dropdown-list scrollable-menu"
      >

        <loading-icon v-if="isLoading"/>

        <ul
          v-else
          v-html="dropdownContent"
        >
        </ul>
      </li>
    </ul>
  </div>
</template>
