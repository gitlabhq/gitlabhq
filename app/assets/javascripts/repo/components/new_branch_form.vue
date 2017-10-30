<script>
  import flash, { hideFlash } from '../../flash';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import eventHub from '../event_hub';

  export default {
    components: {
      loadingIcon,
    },
    props: {
      currentBranch: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        branchName: '',
        loading: false,
      };
    },
    computed: {
      btnDisabled() {
        return this.loading || this.branchName === '';
      },
    },
    methods: {
      toggleDropdown() {
        this.$dropdown.dropdown('toggle');
      },
      submitNewBranch() {
        // need to query as the element is appended outside of Vue
        const flashEl = this.$refs.flashContainer.querySelector('.flash-alert');

        this.loading = true;

        if (flashEl) {
          hideFlash(flashEl, false);
        }

        eventHub.$emit('createNewBranch', this.branchName);
      },
      showErrorMessage(message) {
        this.loading = false;
        flash(message, 'alert', this.$el);
      },
      createdNewBranch(newBranchName) {
        this.loading = false;
        this.branchName = '';

        if (this.dropdownText) {
          this.dropdownText.textContent = newBranchName;
        }
      },
    },
    created() {
      // Dropdown is outside of Vue instance & is controlled by Bootstrap
      this.$dropdown = $('.git-revision-dropdown');

      // text element is outside Vue app
      this.dropdownText = document.querySelector('.project-refs-form .dropdown-toggle-text');

      eventHub.$on('createNewBranchSuccess', this.createdNewBranch);
      eventHub.$on('createNewBranchError', this.showErrorMessage);
      eventHub.$on('toggleNewBranchDropdown', this.toggleDropdown);
    },
    destroyed() {
      eventHub.$off('createNewBranchSuccess', this.createdNewBranch);
      eventHub.$off('toggleNewBranchDropdown', this.toggleDropdown);
      eventHub.$off('createNewBranchError', this.showErrorMessage);
    },
  };
</script>

<template>
  <div>
    <div
      class="flash-container"
      ref="flashContainer"
    >
    </div>
    <p>
      Create from:
      <code>{{ currentBranch }}</code>
    </p>
    <input
      class="form-control js-new-branch-name"
      type="text"
      placeholder="Name new branch"
      v-model="branchName"
      @keyup.enter.stop.prevent="submitNewBranch"
    />
    <div class="prepend-top-default clearfix">
      <button
        type="button"
        class="btn btn-primary pull-left"
        :disabled="btnDisabled"
        @click.stop.prevent="submitNewBranch"
      >
        <loading-icon
          v-if="loading"
          :inline="true"
        />
        <span>Create</span>
      </button>
      <button
        type="button"
        class="btn btn-default pull-right"
        @click.stop.prevent="toggleDropdown"
      >
        Cancel
      </button>
    </div>
  </div>
</template>
