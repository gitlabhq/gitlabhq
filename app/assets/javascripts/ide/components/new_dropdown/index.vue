<script>
  import newModal from './modal.vue';
  import upload from './upload.vue';
  import icon from '../../../vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
      newModal,
      upload,
    },
    props: {
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
        default: null,
      },
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
        this.openModal = true;
      },
      hideModal() {
        this.openModal = false;
      },
    },
  };
</script>

<template>
  <div class="repo-new-btn pull-right">
    <div class="dropdown">
      <button
        type="button"
        class="btn btn-sm btn-default dropdown-toggle add-to-tree"
        data-toggle="dropdown"
        aria-label="Create new file or directory"
      >
        <icon
          name="plus"
          :size="12"
          css-classes="pull-left"
        />
        <icon
          name="arrow-down"
          :size="12"
          css-classes="pull-left"
        />
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
            :branch-id="branch"
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
      :branch-id="branch"
      :path="path"
      :parent="parent"
      @hide="hideModal"
    />
  </div>
</template>
