<script>
import { mapActions } from 'vuex';
import icon from '~/vue_shared/components/icon.vue';
import newModal from './modal.vue';
import upload from './upload.vue';

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
  },
  data() {
    return {
      openModal: false,
      modalType: '',
      dropdownOpen: false,
    };
  },
  methods: {
    ...mapActions(['createTempEntry']),
    createNewItem(type) {
      this.modalType = type;
      this.openModal = true;
      this.dropdownOpen = false;
    },
    hideModal() {
      this.openModal = false;
    },
    openDropdown() {
      this.dropdownOpen = !this.dropdownOpen;
    },
  },
};
</script>

<template>
  <div class="ide-new-btn">
    <div
      class="dropdown"
      :class="{
        open: dropdownOpen,
      }"
    >
      <button
        type="button"
        class="btn btn-sm btn-default dropdown-toggle add-to-tree"
        aria-label="Create new file or directory"
        @click.stop="openDropdown()"
        @blur="openDropdown"
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
            @click.stop.prevent="createNewItem('blob')"
          >
            {{ __('New file') }}
          </a>
        </li>
        <li>
          <upload
            :branch-id="branch"
            :path="path"
            @create="createTempEntry"
          />
        </li>
        <li>
          <a
            href="#"
            role="button"
            @click.stop.prevent="createNewItem('tree')"
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
      @hide="hideModal"
      @create="createTempEntry"
    />
  </div>
</template>
