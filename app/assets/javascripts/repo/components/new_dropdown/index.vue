<script>
  import RepoHelper from '../../helpers/repo_helper';
  import RepoStore from '../../stores/repo_store';
  import eventHub from '../../event_hub';
  import newModal from './modal.vue';

  export default {
    components: {
      newModal,
    },
    data() {
      return {
        openModal: false,
        modalType: '',
        currentPath: RepoStore.path,
      };
    },
    methods: {
      createNewItem(type) {
        this.modalType = type;
        this.toggleModalOpen();
      },
      toggleModalOpen() {
        this.openModal = !this.openModal;
      },
      createNewEntryInStore(name, type) {
        RepoHelper.createNewEntry(name, type);

        this.toggleModalOpen();
      },
    },
    created() {
      eventHub.$on('createNewEntry', this.createNewEntryInStore);
    },
    beforeDestroy() {
      eventHub.$off('createNewEntry', this.createNewEntryInStore);
    },
  };
</script>

<template>
  <div>
    <ul class="breadcrumb repo-breadcrumb">
      <li class="dropdown">
        <button
          type="button"
          class="btn btn-default dropdown-toggle add-to-tree"
          data-toggle="dropdown"
          aria-label="Create new file or directory"
        >
          <i
            class="fa fa-plus"
            aria-hidden="true"
          >
          </i>
        </button>
        <ul class="dropdown-menu">
          <li>
            <a
              href="#"
              role="button"
              @click.prevent="createNewItem('blob')"
            >
              {{ __('New file') }}
            </a>
          </li>
          <li>
            <a
              href="#"
              role="button"
              @click.prevent="createNewItem('tree')"
            >
              {{ __('New directory') }}
            </a>
          </li>
        </ul>
      </li>
    </ul>
    <new-modal
      v-if="openModal"
      :type="modalType"
      :current-path="currentPath"
      @toggle="toggleModalOpen"
    />
  </div>
</template>
