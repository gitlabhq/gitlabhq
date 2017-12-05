<script>
  import { mapState } from 'vuex';
  import newModal from './modal.vue';
  import upload from './upload.vue';

  export default {
    props: {
      projectId: {
        type: String,
        required: true,
      },
      branch: {
        type: String,
        required: true,
      },
      path: {
        type: String,
        required: true,
      },
      parent: {
        type: Object,
        required: false,
      },
    },
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
    methods: {
      createNewItem(type) {
        this.modalType = type;
        this.toggleModalOpen();
      },
      toggleModalOpen() {
        this.openModal = !this.openModal;
      },
    },
    computed: {
      ...mapState([
        'trees',
      ]),
    }
  };
</script>

<template>
  <div class="repo-new-btn">
    <div class="dropdown">
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
            :projectId="projectId"
            :branchId="branch"
            :path="path"
            :parent="parent"
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
    </div>
    <new-modal
      v-if="openModal"
      :type="modalType"
      :projectId="projectId"
      :branchId="branch"
      :path="path"
      :parent="parent"
      @toggle="toggleModalOpen"
    />
  </div>
</template>
