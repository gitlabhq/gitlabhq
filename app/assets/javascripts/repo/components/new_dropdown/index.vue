<script>
  import { mapState } from 'vuex';
  import newModal from './modal.vue';
  import upload from './upload.vue';

  export default {
    components: {
      newModal,
      upload,
    },
    data() {
      return {
        openModal: false,
        modalType: '',
      };
    },
    computed: {
      ...mapState([
        'path',
      ]),
    },
    methods: {
      createNewItem(type) {
        this.modalType = type;
        this.toggleModalOpen();
      },
      toggleModalOpen() {
        this.openModal = !this.openModal;
      },
<<<<<<< HEAD
      createNewEntryInStore(options, openEditMode = true) {
        RepoHelper.createNewEntry(options, openEditMode);

        if (options.toggleModal) {
          this.toggleModalOpen();
        }
      },
    },
    created() {
      eventHub.$on('createNewEntry', this.createNewEntryInStore);
    },
    beforeDestroy() {
      eventHub.$off('createNewEntry', this.createNewEntryInStore);
=======
>>>>>>> e24d1890aea9c550e02d9145f50e8e1ae153a3a3
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
            <upload
              :current-path="currentPath"
            />
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
      :path="path"
      @toggle="toggleModalOpen"
    />
  </div>
</template>
