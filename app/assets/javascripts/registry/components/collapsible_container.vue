<script>
  import { mapActions } from 'vuex';
  import { n__, s__ } from '../../locale';
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';
  import tableRegistry from './table_registry.vue';
  import { errorMessages, errorMessagesTypes } from '../constants';

  export default {
    name: 'collapsibeContainerRegisty',
    props: {
      repo: {
        type: Object,
        required: true,
      },
    },
    components: {
      clipboardButton,
      loadingIcon,
      tableRegistry,
    },
    directives: {
      tooltip,
    },
    data() {
      return {
        isOpen: false,
      };
    },
    methods: {
      ...mapActions([
        'fetchRepos',
        'fetchList',
        'deleteRepo',
      ]),

      toggleRepo() {
        this.isOpen = !this.isOpen;
        if (this.isOpen) {
          this.fetchList({ repo: this.repo })
          .catch(() => this.showError(errorMessagesTypes.FETCH_REGISTRY));
        }
      },

      handleDeleteRepository() {
        this.deleteRepo(this.repo)
          .then(() => this.fetchRepos())
          .catch(() => this.showError(errorMessagesTypes.DELETE_REPO));
      },

      clipboardText(text) {
        return `docker pull ${text}`;
      },

      showError(message) {
        Flash((errorMessages[message]));
      },
    },
  };
</script>

<template>
  <div class="container-image">
    <div
      class="container-image-head">
      <button
        type="button"
        @click="toggleRepo"
        class="js-toggle-repo btn-link">
        <i
          class="fa"
          :class="{
            'fa-chevron-right': !isOpen,
            'fa-chevron-up': isOpen,
          }"
          aria-hidden="true">
        </i>
        {{repo.name}}
      </button>

      <clipboard-button
        v-if="repo.location"
        :text="clipboardText(repo.location)"
        :title="repo.location"
        />

      <div class="controls hidden-xs pull-right">
        <button
          v-if="repo.canDelete"
          type="button"
          class="js-remove-repo btn btn-danger"
          :title="s__('ContainerRegistry|Remove repository')"
          :aria-label="s__('ContainerRegistry|Remove repository')"
          v-tooltip
          @click="handleDeleteRepository">
          <i
            class="fa fa-trash"
            aria-hidden="true">
          </i>
        </button>
      </div>

    </div>

    <loading-icon
      v-if="repo.isLoading"
      />

    <div
      v-else-if="!repo.isLoading && isOpen"
      class="container-image-tags">

      <table-registry
        v-if="repo.list.length"
        :repo="repo"
        />

      <div
        v-else
        class="nothing-here-block">
        {{s__("ContainerRegistry|No tags in Container Registry for this container image.")}}
      </div>
    </div>
  </div>
</template>
