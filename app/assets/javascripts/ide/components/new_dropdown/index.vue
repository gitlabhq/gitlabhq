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
      required: false,
      default: '',
    },
  },
  data() {
    return {
      openModal: false,
      modalType: '',
      dropdownOpen: false,
    };
  },
  watch: {
    dropdownOpen() {
      this.$nextTick(() => {
        this.$refs.dropdownMenu.scrollIntoView();
      });
    },
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
      :class="{
        show: dropdownOpen,
      }"
      class="dropdown"
    >
      <button
        type="button"
        class="btn btn-sm btn-default dropdown-toggle add-to-tree"
        aria-label="Create new file or directory"
        @click.stop="openDropdown()"
      >
        <icon
          :size="12"
          name="plus"
          css-classes="float-left"
        />
        <icon
          :size="12"
          name="arrow-down"
          css-classes="float-left"
        />
      </button>
      <ul
        ref="dropdownMenu"
        class="dropdown-menu dropdown-menu-right"
      >
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
