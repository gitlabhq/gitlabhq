<script>
import { mapActions } from 'vuex';
import {
  GlButton,
  GlFormCheckbox,
  GlTooltipDirective,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { n__, s__, sprintf } from '../../locale';
import createFlash from '../../flash';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import TablePagination from '../../vue_shared/components/pagination/table_pagination.vue';
import Icon from '../../vue_shared/components/icon.vue';
import timeagoMixin from '../../vue_shared/mixins/timeago';
import { errorMessages, errorMessagesTypes } from '../constants';
import { numberToHumanSize } from '../../lib/utils/number_utils';

export default {
  components: {
    ClipboardButton,
    TablePagination,
    GlFormCheckbox,
    GlButton,
    Icon,
    GlModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [timeagoMixin],
  props: {
    repo: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      itemsToBeDeleted: [],
      modalId: `confirm-image-deletion-modal-${this.repo.id}`,
      selectAllChecked: false,
      modalDescription: '',
    };
  },
  computed: {
    bulkDeletePath() {
      return this.repo.tagsPath ? this.repo.tagsPath.replace('?format=json', '/bulk_destroy') : '';
    },
    shouldRenderPagination() {
      return this.repo.pagination.total > this.repo.pagination.perPage;
    },
    modalTitle() {
      return n__(
        'ContainerRegistry|Remove image',
        'ContainerRegistry|Remove images',
        this.itemsToBeDeleted.length === 0 ? 1 : this.itemsToBeDeleted.length,
      );
    },
  },
  methods: {
    ...mapActions(['fetchList', 'deleteItem', 'multiDeleteItems']),
    setModalDescription(itemsToDeleteLength, itemIndex) {
      if (itemsToDeleteLength) {
        this.modalDescription = sprintf(
          s__(`ContainerRegistry|You are about to delete <b>%{count}</b> images. This will
              delete the images and all tags pointing to them.`),
          { count: itemsToDeleteLength },
        );
      } else {
        const { tag } = this.repo.list[itemIndex];

        this.modalDescription = sprintf(
          s__(`ContainerRegistry|You are about to delete the image <b>%{title}</b>. This will
              delete the image and all tags pointing to this image.`),
          { title: `${this.repo.name}:${tag}` },
        );
      }
    },
    layers(item) {
      return item.layers ? n__('%d layer', '%d layers', item.layers) : '';
    },
    formatSize(size) {
      return numberToHumanSize(size);
    },
    removeModalEvents() {
      this.$refs.deleteModal.$refs.modal.$off('ok');
      this.$refs.deleteModal.$refs.modal.$off('hide');
    },
    deleteSingleItem(index) {
      this.setModalDescription(0, index);

      this.$refs.deleteModal.$refs.modal.$once('ok', () => {
        this.removeModalEvents();
        this.handleSingleDelete(this.repo.list[index]);
      });

      this.$refs.deleteModal.$refs.modal.$once('hide', this.removeModalEvents);
    },
    deleteMultipleItems() {
      this.$refs.deleteModal.$refs.modal.$once('ok', () => {
        this.removeModalEvents();
        this.handleMultipleDelete();
      });

      this.$refs.deleteModal.$refs.modal.$once('hide', this.removeModalEvents);
    },
    handleSingleDelete(itemToDelete) {
      this.deleteItem(itemToDelete)
        .then(() => this.fetchList({ repo: this.repo }))
        .catch(() => this.showError(errorMessagesTypes.DELETE_REGISTRY));
    },
    handleMultipleDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];

      if (this.bulkDeletePath) {
        this.multiDeleteItems({
          path: this.bulkDeletePath,
          items: itemsToBeDeleted.map(x => this.repo.list[x].tag),
        })
          .then(() => this.fetchList({ repo: this.repo }))
          .catch(() => this.showError(errorMessagesTypes.DELETE_REGISTRY));
      } else {
        this.showError(errorMessagesTypes.DELETE_REGISTRY);
      }
    },
    onPageChange(pageNumber) {
      this.fetchList({ repo: this.repo, page: pageNumber }).catch(() =>
        this.showError(errorMessagesTypes.FETCH_REGISTRY),
      );
    },
    showError(message) {
      createFlash(errorMessages[message]);
    },
    onSelectAllChange() {
      if (this.selectAllChecked) {
        this.deselectAll();
      } else {
        this.selectAll();
      }
    },
    selectAll() {
      this.itemsToBeDeleted = this.repo.list.map((x, index) => index);
      this.selectAllChecked = true;
      this.setModalDescription(this.itemsToBeDeleted.length);
    },
    deselectAll() {
      this.itemsToBeDeleted = [];
      this.selectAllChecked = false;
    },
    updateItemsToBeDeleted(index) {
      const delIndex = this.itemsToBeDeleted.findIndex(x => x === index);

      if (delIndex > -1) {
        this.itemsToBeDeleted.splice(delIndex, 1);
        this.selectAllChecked = false;
      } else {
        this.itemsToBeDeleted.push(index);

        if (this.itemsToBeDeleted.length === this.repo.list.length) {
          this.selectAllChecked = true;
        }
      }

      if (this.itemsToBeDeleted.length === 1) {
        this.setModalDescription(0, this.itemsToBeDeleted[0]);
      } else if (this.itemsToBeDeleted.length > 1) {
        this.setModalDescription(this.itemsToBeDeleted.length);
      }
    },
  },
};
</script>
<template>
  <div>
    <table class="table tags">
      <thead>
        <tr>
          <th>
            <gl-form-checkbox
              v-if="repo.canDelete"
              class="js-select-all-checkbox"
              :checked="selectAllChecked"
              @change="onSelectAllChange"
            />
          </th>
          <th>{{ s__('ContainerRegistry|Tag') }}</th>
          <th>{{ s__('ContainerRegistry|Tag ID') }}</th>
          <th>{{ s__('ContainerRegistry|Size') }}</th>
          <th>{{ s__('ContainerRegistry|Last Updated') }}</th>
          <th>
            <gl-button
              v-if="repo.canDelete"
              v-gl-tooltip
              v-gl-modal="modalId"
              :disabled="!itemsToBeDeleted || itemsToBeDeleted.length === 0"
              class="js-delete-registry float-right"
              variant="danger"
              :title="s__('ContainerRegistry|Remove selected images')"
              :aria-label="s__('ContainerRegistry|Remove selected images')"
              @click="deleteMultipleItems()"
              ><icon name="remove"
            /></gl-button>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(item, index) in repo.list" :key="item.tag" class="registry-image-row">
          <td class="check">
            <gl-form-checkbox
              v-if="item.canDelete"
              class="js-select-checkbox"
              :checked="itemsToBeDeleted && itemsToBeDeleted.includes(index)"
              @change="updateItemsToBeDeleted(index)"
            />
          </td>
          <td class="monospace">
            {{ item.tag }}
            <clipboard-button
              v-if="item.location"
              :title="item.location"
              :text="item.location"
              css-class="btn-default btn-transparent btn-clipboard"
            />
          </td>
          <td>
            <span v-gl-tooltip.bottom class="monospace" :title="item.revision">
              {{ item.shortRevision }}
            </span>
          </td>
          <td>
            {{ formatSize(item.size) }}
            <template v-if="item.size && item.layers"
              >&middot;</template
            >
            {{ layers(item) }}
          </td>

          <td>
            <span v-gl-tooltip.bottom :title="tooltipTitle(item.createdAt)">
              {{ timeFormated(item.createdAt) }}
            </span>
          </td>

          <td class="content action-buttons">
            <gl-button
              v-if="item.canDelete"
              v-gl-modal="modalId"
              :title="s__('ContainerRegistry|Remove image')"
              :aria-label="s__('ContainerRegistry|Remove image')"
              variant="danger"
              class="js-delete-registry-row float-right btn-inverted btn-border-color btn-icon"
              @click="deleteSingleItem(index)"
            >
              <icon name="remove" />
            </gl-button>
          </td>
        </tr>
      </tbody>
    </table>

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onPageChange"
      :page-info="repo.pagination"
    />

    <gl-modal ref="deleteModal" :modal-id="modalId" ok-variant="danger">
      <template v-slot:modal-title>{{ modalTitle }}</template>
      <template v-slot:modal-ok>{{ s__('ContainerRegistry|Remove image(s) and tags') }}</template>
      <p v-html="modalDescription"></p>
    </gl-modal>
  </div>
</template>
