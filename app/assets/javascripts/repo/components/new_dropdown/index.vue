<script>
  import newModal from './modal.vue';

  export default {
    components: {
      newModal,
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
  };
</script>

<template>
  <div class="breadcrumb repo-breadcrumb">
    <div class="dropdown">
      <button
        type="button"
        class="btn btn-default dropdown-toggle add-to-tree"
        data-toggle="dropdown"
        data-target=".add-to-tree-dropdown"
      >
        <i
          class="fa fa-plus"
          aria-hidden="true"
        >
        </i>
      </button>
    </div>
    <div class="add-to-tree-dropdown">
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
    </div>
    <new-modal
      v-if="openModal"
      :type="modalType"
      @toggle="toggleModalOpen"
    />
  </div>
</template>
