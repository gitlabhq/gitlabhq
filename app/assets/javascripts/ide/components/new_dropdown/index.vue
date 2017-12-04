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
    },
  };
</script>

<template>
  <div>
    <ul class="breadcrumb repo-breadcrumb repo-new-btn">
      <li class="dropdown">
        <button
          type="button"
          class="btn btn-sm btn-default dropdown-toggle add-to-tree"
          data-toggle="dropdown"
          aria-label="Create new file or directory"
        >
          <i
            class="fa fa-plus"
            aria-hidden="true"
          >
          </i>
        </button>
        <ul class="dropdown-menu dropdown-menu-right">
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
              :path="path"
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
