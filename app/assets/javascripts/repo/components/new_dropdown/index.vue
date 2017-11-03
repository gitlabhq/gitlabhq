<script>
  import { mapState, mapActions } from 'vuex';
  import newModal from './modal.vue';
  import upload from './upload.vue';

  export default {
    components: {
      newModal,
      upload,
    },
    computed: {
      ...mapState([
        'path',
        'newEntryModalOpen',
      ]),
    },
    methods: {
      ...mapActions([
        'openNewEntryModal',
      ]),
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
              @click.prevent="openNewEntryModal('blob')"
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
              @click.prevent="openNewEntryModal('tree')"
            >
              {{ __('New directory') }}
            </a>
          </li>
        </ul>
      </li>
    </ul>
    <new-modal
      v-if="newEntryModalOpen"
      :path="path"
      @toggle="openNewEntryModal"
    />
  </div>
</template>
