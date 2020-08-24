<script>
import { mapActions } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import upload from './upload.vue';
import ItemButton from './button.vue';
import { modalTypes } from '../../constants';
import NewModal from './modal.vue';

export default {
  components: {
    GlIcon,
    upload,
    ItemButton,
    NewModal,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: false,
      default: '',
    },
    isOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    isOpen() {
      this.$nextTick(() => {
        this.$refs.dropdownMenu.scrollIntoView({
          block: 'nearest',
        });
      });
    },
  },
  methods: {
    ...mapActions(['createTempEntry', 'deleteEntry']),
    createNewItem(type) {
      this.$refs.newModal.open(type, this.path);
      this.$emit('toggle', false);
    },
    openDropdown() {
      this.$emit('toggle', !this.isOpen);
    },
  },
  modalTypes,
};
</script>

<template>
  <div class="ide-new-btn">
    <div
      :class="{
        show: isOpen,
      }"
      class="dropdown d-flex"
    >
      <button
        :aria-label="__('Create new file or directory')"
        type="button"
        class="rounded border-0 d-flex ide-entry-dropdown-toggle"
        data-qa-selector="dropdown_button"
        @click.stop="openDropdown()"
      >
        <gl-icon name="ellipsis_v" /> <gl-icon name="chevron-down" />
      </button>
      <ul ref="dropdownMenu" class="dropdown-menu dropdown-menu-right">
        <template v-if="type === 'tree'">
          <li>
            <item-button
              :label="__('New file')"
              class="d-flex"
              icon="doc-new"
              icon-classes="mr-2"
              @click="createNewItem('blob')"
            />
          </li>
          <li><upload :path="path" @create="createTempEntry" /></li>
          <li>
            <item-button
              :label="__('New directory')"
              class="d-flex"
              icon="folder-new"
              icon-classes="mr-2"
              @click="createNewItem($options.modalTypes.tree)"
            />
          </li>
          <li class="divider"></li>
        </template>
        <li>
          <item-button
            :label="__('Rename/Move')"
            class="d-flex"
            icon="pencil"
            icon-classes="mr-2"
            data-qa-selector="rename_move_button"
            @click="createNewItem($options.modalTypes.rename)"
          />
        </li>
        <li>
          <item-button
            :label="__('Delete')"
            class="d-flex"
            icon="remove"
            icon-classes="mr-2"
            @click="deleteEntry(path)"
          />
        </li>
      </ul>
    </div>
    <new-modal ref="newModal" />
  </div>
</template>
