<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { modalTypes } from '../../constants';
import ItemButton from './button.vue';
import NewModal from './modal.vue';
import Upload from './upload.vue';

export default {
  components: {
    GlIcon,
    Upload,
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
      class="dropdown gl-flex"
    >
      <button
        :aria-label="__('Create new file or directory')"
        type="button"
        class="rounded border-0 ide-entry-dropdown-toggle gl-flex"
        @click.stop="openDropdown()"
      >
        <gl-icon name="ellipsis_v" />
      </button>
      <ul ref="dropdownMenu" class="dropdown-menu dropdown-menu-right" data-testid="dropdown-menu">
        <template v-if="type === 'tree'">
          <li>
            <item-button
              :label="__('New file')"
              class="gl-flex"
              icon="doc-new"
              icon-classes="mr-2"
              @click="createNewItem('blob')"
            />
          </li>
          <upload :path="path" @create="createTempEntry" />
          <li>
            <item-button
              :label="__('New directory')"
              class="gl-flex"
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
            class="gl-flex"
            icon="pencil"
            icon-classes="mr-2"
            @click="createNewItem($options.modalTypes.rename)"
          />
        </li>
        <li>
          <item-button
            :label="__('Delete')"
            class="gl-flex"
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
