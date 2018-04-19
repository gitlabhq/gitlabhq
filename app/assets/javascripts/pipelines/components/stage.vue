<script>
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

  import $ from 'jquery';
  import Flash from '../../flash';
  import axios from '../../lib/utils/axios_utils';
  import eventHub from '../event_hub';
  import Icon from '../../vue_shared/components/icon.vue';
  import LoadingIcon from '../../vue_shared/components/loading_icon.vue';
  import JobComponent from './graph/job_component.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    components: {
      LoadingIcon,
      Icon,
      JobComponent,
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
        // return this.dropdownContent.length > 0
        //   ? 'js-builds-dropdown-container'
        //   : 'js-builds-dropdown-loading';
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
        if (this.updateDropdown && this.isDropdownOpen() && !this.isLoading) {
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
          eventHub.$emit('clickedDropdown');
          this.isLoading = true;
          this.fetchJobs();
        }
      },

      fetchJobs() {
        axios
          .get(this.stage.dropdown_path)
          .then(({ data }) => {
            // TODO: REMOVE THIS ONCE WE HAVE BACKEND
            this.dropdownContent = [
              {
                id: 966,
                name: 'rspec:linux 0 3',
                started: false,
                build_path: '/twitter/flight/-/jobs/966',
                cancel_path: '/twitter/flight/-/jobs/966/cancel',
                playable: false,
                created_at: '2018-04-18T12:10:14.315Z',
                updated_at: '2018-04-18T12:10:14.500Z',
                status: {
                  icon: 'status_pending',
                  text: 'pending',
                  label: 'pending',
                  group: 'pending',
                  tooltip: 'pending',
                  has_details: true,
                  details_path: '/twitter/flight/-/jobs/966',
                  favicon:
                    '/assets/ci_favicons/dev/favicon_status_pending-db32e1faf94b9f89530ac519790920d1f18ea8f6af6cd2e0a26cd6840cacf101.ico',
                  action: {
                    icon: 'cancel',
                    title: 'Cancel',
                    path: '/twitter/flight/-/jobs/966/cancel',
                    method: 'post',
                  },
                },
              },
              {
                id: 208,
                name: 'rspec:linux 1 3',
                started: '2018-03-07T06:41:46.233Z',
                build_path: '/twitter/flight/-/jobs/208',
                retry_path: '/twitter/flight/-/jobs/208/retry',
                playable: false,
                created_at: '2018-03-07T14:41:57.559Z',
                updated_at: '2018-03-07T14:41:57.559Z',
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/twitter/flight/-/jobs/208',
                  favicon:
                    '/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/twitter/flight/-/jobs/208/retry',
                    method: 'post',
                  },
                },
              },
              {
                id: 209,
                name: 'rspec:linux 2 3',
                started: '2018-03-07T06:41:46.233Z',
                build_path: '/twitter/flight/-/jobs/209',
                retry_path: '/twitter/flight/-/jobs/209/retry',
                playable: false,
                created_at: '2018-03-07T14:41:57.605Z',
                updated_at: '2018-03-07T14:41:57.605Z',
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/twitter/flight/-/jobs/209',
                  favicon:
                    '/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/twitter/flight/-/jobs/209/retry',
                    method: 'post',
                  },
                },
              },
              {
                id: 63701097,
                name: 'spinach-mysql 0 2',
                started: false,
                build_path: '/gitlab-org/gitlab-ce/-/jobs/63701097',
                playable: false,
                created_at: '2018-04-18T15:16:52.707Z',
                updated_at: '2018-04-18T15:16:52.707Z',
                status: {
                  icon: 'status_created',
                  text: 'created',
                  label: 'created',
                  group: 'created',
                  tooltip: 'created',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ce/-/jobs/63701097',
                  favicon:
                    'https://assets.gitlab-static.net/assets/ci_favicons/favicon_status_created-e997aa0b7db73165df8a9d6803932b18d7b7cc37d604d2d96e378fea2dba9c5f.ico',
                },
              },
              {
                id: 63701098,
                name: 'spinach-mysql 1 2',
                started: false,
                build_path: '/gitlab-org/gitlab-ce/-/jobs/63701098',
                playable: false,
                created_at: '2018-04-18T15:16:52.808Z',
                updated_at: '2018-04-18T15:16:52.808Z',
                status: {
                  icon: 'status_created',
                  text: 'created',
                  label: 'created',
                  group: 'created',
                  tooltip: 'created',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-ce/-/jobs/63701098',
                  favicon:
                    'https://assets.gitlab-static.net/assets/ci_favicons/favicon_status_created-e997aa0b7db73165df8a9d6803932b18d7b7cc37d604d2d96e378fea2dba9c5f.ico',
                },
              },
            ];
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
        $(
          this.$el.querySelectorAll('.js-builds-dropdown-list a.mini-pipeline-graph-dropdown-item'),
        ).on('click', e => {
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
        class="js-builds-dropdown-list scrollable-menu"
      >

        <loading-icon v-if="isLoading"/>

        <ul
          v-else
        >
          <li
            v-for="job in dropdownContent"
            :key="job.id"
        >
            <job-component
              :job="job"
              css-class-job-name="mini-pipeline-graph-dropdown-item"
            />
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>
