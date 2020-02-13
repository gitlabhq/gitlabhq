<script>
import { mapState, mapActions } from 'vuex';
import {
  GlTable,
  GlFormCheckbox,
  GlButton,
  GlIcon,
  GlTooltipDirective,
  GlPagination,
  GlModal,
  GlLoadingIcon,
  GlSprintf,
  GlEmptyState,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { n__, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import Tracking from '~/tracking';
import {
  LIST_KEY_TAG,
  LIST_KEY_IMAGE_ID,
  LIST_KEY_SIZE,
  LIST_KEY_LAST_UPDATED,
  LIST_KEY_ACTIONS,
  LIST_KEY_CHECKBOX,
  LIST_LABEL_TAG,
  LIST_LABEL_IMAGE_ID,
  LIST_LABEL_SIZE,
  LIST_LABEL_LAST_UPDATED,
} from '../constants';

export default {
  components: {
    GlTable,
    GlFormCheckbox,
    GlButton,
    GlIcon,
    ClipboardButton,
    GlPagination,
    GlModal,
    GlLoadingIcon,
    GlSprintf,
    GlEmptyState,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [timeagoMixin, Tracking.mixin()],
  data() {
    return {
      selectedItems: [],
      itemsToBeDeleted: [],
      selectAllChecked: false,
      modalDescription: null,
      isDesktop: true,
    };
  },
  computed: {
    ...mapState(['tags', 'tagsPagination', 'isLoading', 'config']),
    imageName() {
      const { name } = JSON.parse(window.atob(this.$route.params.id));
      return name;
    },
    fields() {
      return [
        { key: LIST_KEY_CHECKBOX, label: '' },
        { key: LIST_KEY_TAG, label: LIST_LABEL_TAG },
        { key: LIST_KEY_IMAGE_ID, label: LIST_LABEL_IMAGE_ID },
        { key: LIST_KEY_SIZE, label: LIST_LABEL_SIZE },
        { key: LIST_KEY_LAST_UPDATED, label: LIST_LABEL_LAST_UPDATED },
        { key: LIST_KEY_ACTIONS, label: '' },
      ].filter(f => f.key !== LIST_KEY_CHECKBOX || this.isDesktop);
    },
    isMultiDelete() {
      return this.itemsToBeDeleted.length > 1;
    },
    tracking() {
      return {
        label: this.isMultiDelete ? 'bulk_registry_tag_delete' : 'registry_tag_delete',
      };
    },
    modalAction() {
      return n__(
        'ContainerRegistry|Remove tag',
        'ContainerRegistry|Remove tags',
        this.isMultiDelete ? this.itemsToBeDeleted.length : 1,
      );
    },
    currentPage: {
      get() {
        return this.tagsPagination.page;
      },
      set(page) {
        this.requestTagsList({ pagination: { page }, id: this.$route.params.id });
      },
    },
  },
  methods: {
    ...mapActions(['requestTagsList', 'requestDeleteTag', 'requestDeleteTags']),
    setModalDescription(itemIndex = -1) {
      if (itemIndex === -1) {
        this.modalDescription = {
          message: s__(`ContainerRegistry|You are about to remove %{item} tags. Are you sure?`),
          item: this.itemsToBeDeleted.length,
        };
      } else {
        const { path } = this.tags[itemIndex];

        this.modalDescription = {
          message: s__(`ContainerRegistry|You are about to remove %{item}. Are you sure?`),
          item: path,
        };
      }
    },
    formatSize(size) {
      return numberToHumanSize(size);
    },
    layers(layers) {
      return layers ? n__('%d layer', '%d layers', layers) : '';
    },
    onSelectAllChange() {
      if (this.selectAllChecked) {
        this.deselectAll();
      } else {
        this.selectAll();
      }
    },
    selectAll() {
      this.selectedItems = this.tags.map((x, index) => index);
      this.selectAllChecked = true;
    },
    deselectAll() {
      this.selectedItems = [];
      this.selectAllChecked = false;
    },
    updateSelectedItems(index) {
      const delIndex = this.selectedItems.findIndex(x => x === index);

      if (delIndex > -1) {
        this.selectedItems.splice(delIndex, 1);
        this.selectAllChecked = false;
      } else {
        this.selectedItems.push(index);

        if (this.selectedItems.length === this.tags.length) {
          this.selectAllChecked = true;
        }
      }
    },
    deleteSingleItem(index) {
      this.setModalDescription(index);
      this.itemsToBeDeleted = [index];
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    deleteMultipleItems() {
      this.itemsToBeDeleted = [...this.selectedItems];
      if (this.selectedItems.length === 1) {
        this.setModalDescription(this.itemsToBeDeleted[0]);
      } else if (this.selectedItems.length > 1) {
        this.setModalDescription();
      }
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    handleSingleDelete(itemToDelete) {
      this.itemsToBeDeleted = [];
      this.requestDeleteTag({ tag: itemToDelete, imageId: this.$route.params.id });
    },
    handleMultipleDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];
      this.selectedItems = [];

      this.requestDeleteTags({
        ids: itemsToBeDeleted.map(x => this.tags[x].name),
        imageId: this.$route.params.id,
      });
    },
    onDeletionConfirmed() {
      this.track('confirm_delete');
      if (this.isMultiDelete) {
        this.handleMultipleDelete();
      } else {
        const index = this.itemsToBeDeleted[0];
        this.handleSingleDelete(this.tags[index]);
      }
    },
    handleResize() {
      this.isDesktop = GlBreakpointInstance.isDesktop();
    },
  },
};
</script>

<template>
  <div
    v-gl-resize-observer="handleResize"
    class="my-3 position-absolute w-100 slide-enter-to-element"
  >
    <div class="d-flex my-3 align-items-center">
      <h4>
        <gl-sprintf :message="s__('ContainerRegistry|%{imageName} tags')">
          <template #imageName>
            {{ imageName }}
          </template>
        </gl-sprintf>
      </h4>
    </div>
    <gl-loading-icon v-if="isLoading" />
    <template v-else-if="tags.length > 0">
      <gl-table :items="tags" :fields="fields" :stacked="!isDesktop">
        <template v-if="isDesktop" #head(checkbox)>
          <gl-form-checkbox
            ref="mainCheckbox"
            :checked="selectAllChecked"
            @change="onSelectAllChange"
          />
        </template>
        <template #head(actions)>
          <gl-button
            ref="bulkDeleteButton"
            v-gl-tooltip
            :disabled="!selectedItems || selectedItems.length === 0"
            class="float-right"
            variant="danger"
            :title="s__('ContainerRegistry|Remove selected tags')"
            :aria-label="s__('ContainerRegistry|Remove selected tags')"
            @click="deleteMultipleItems()"
          >
            <gl-icon name="remove" />
          </gl-button>
        </template>

        <template #cell(checkbox)="{index}">
          <gl-form-checkbox
            ref="rowCheckbox"
            class="js-row-checkbox"
            :checked="selectedItems.includes(index)"
            @change="updateSelectedItems(index)"
          />
        </template>
        <template #cell(name)="{item}">
          <span ref="rowName">
            {{ item.name }}
          </span>
          <clipboard-button
            v-if="item.location"
            ref="rowClipboardButton"
            :title="item.location"
            :text="item.location"
            css-class="btn-default btn-transparent btn-clipboard"
          />
        </template>
        <template #cell(short_revision)="{value}">
          <span ref="rowShortRevision">
            {{ value }}
          </span>
        </template>
        <template #cell(total_size)="{item}">
          <span ref="rowSize">
            {{ formatSize(item.total_size) }}
            <template v-if="item.total_size && item.layers">
              &middot;
            </template>
            {{ layers(item.layers) }}
          </span>
        </template>
        <template #cell(created_at)="{value}">
          <span ref="rowTime">
            {{ timeFormatted(value) }}
          </span>
        </template>
        <template #cell(actions)="{index, item}">
          <gl-button
            ref="singleDeleteButton"
            :title="s__('ContainerRegistry|Remove tag')"
            :aria-label="s__('ContainerRegistry|Remove tag')"
            :disabled="!item.destroy_path"
            variant="danger"
            :class="['js-delete-registry float-right btn-inverted btn-border-color btn-icon']"
            @click="deleteSingleItem(index)"
          >
            <gl-icon name="remove" />
          </gl-button>
        </template>
      </gl-table>
      <gl-pagination
        ref="pagination"
        v-model="currentPage"
        :per-page="tagsPagination.perPage"
        :total-items="tagsPagination.total"
        align="center"
        class="w-100"
      />
      <gl-modal
        ref="deleteModal"
        modal-id="delete-tag-modal"
        ok-variant="danger"
        @ok="onDeletionConfirmed"
        @cancel="track('cancel_delete')"
      >
        <template #modal-title>{{ modalAction }}</template>
        <template #modal-ok>{{ modalAction }}</template>
        <p v-if="modalDescription">
          <gl-sprintf :message="modalDescription.message">
            <template #item>
              <b>{{ modalDescription.item }}</b>
            </template>
          </gl-sprintf>
        </p>
      </gl-modal>
    </template>
    <gl-empty-state
      v-else
      :title="s__('ContainerRegistry|This image has no active tags')"
      :svg-path="config.noContainersImage"
      :description="
        s__(
          `ContainerRegistry|The last tag related to this image was recently removed.
            This empty image and any associated data will be automatically removed as part of the regular Garbage Collection process.
            If you have any questions, contact your administrator.`,
        )
      "
      class="mx-auto my-0"
    />
  </div>
</template>
