<script>
import { mapActions, mapGetters } from 'vuex';
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
    canDeleteRepo: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      selectedItems: [],
      itemsToBeDeleted: [],
      modalId: `confirm-image-deletion-modal-${this.repo.id}`,
      selectAllChecked: false,
      modalDescription: '',
    };
  },
  computed: {
    ...mapGetters(['isDeleteDisabled']),
    bulkDeletePath() {
      return this.repo.tagsPath ? this.repo.tagsPath.replace('?format=json', '/bulk_destroy') : '';
    },
    shouldRenderPagination() {
      return this.repo.pagination.total > this.repo.pagination.perPage;
    },
    modalAction() {
      return n__(
        'ContainerRegistry|Remove tag',
        'ContainerRegistry|Remove tags',
        this.itemsToBeDeleted.length === 0 ? 1 : this.itemsToBeDeleted.length,
      );
    },
  },
  mounted() {
    this.$refs.deleteModal.$refs.modal.$on('hide', this.removeModalEvents);
  },
  methods: {
    ...mapActions(['fetchList', 'deleteItem', 'multiDeleteItems']),
    setModalDescription(itemIndex = -1) {
      if (itemIndex === -1) {
        this.modalDescription = sprintf(
          s__(`ContainerRegistry|You are about to remove <b>%{count}</b> tags. Are you sure?`),
          { count: this.itemsToBeDeleted.length },
        );
      } else {
        const { tag } = this.repo.list[itemIndex];

        this.modalDescription = sprintf(
          s__(`ContainerRegistry|You are about to remove <b>%{title}</b>. Are you sure?`),
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
    },
    deleteSingleItem(index) {
      this.setModalDescription(index);
      this.itemsToBeDeleted = [index];

      this.$refs.deleteModal.$refs.modal.$once('ok', () => {
        this.removeModalEvents();
        this.handleSingleDelete(this.repo.list[index]);
      });
    },
    deleteMultipleItems() {
      this.itemsToBeDeleted = [...this.selectedItems];
      if (this.selectedItems.length === 1) {
        this.setModalDescription(this.itemsToBeDeleted[0]);
      } else if (this.selectedItems.length > 1) {
        this.setModalDescription();
      }

      this.$refs.deleteModal.$refs.modal.$once('ok', () => {
        this.removeModalEvents();
        this.handleMultipleDelete();
      });
    },
    handleSingleDelete(itemToDelete) {
      this.itemsToBeDeleted = [];
      this.deleteItem(itemToDelete)
        .then(() => this.fetchList({ repo: this.repo }))
        .catch(() => this.showError(errorMessagesTypes.DELETE_REGISTRY));
    },
    handleMultipleDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];
      this.selectedItems = [];

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
      this.selectedItems = this.repo.list.map((x, index) => index);
      this.selectAllChecked = true;
    },
    deselectAll() {
      this.selectedItems = [];
      this.selectAllChecked = false;
    },
    updateselectedItems(index) {
      const delIndex = this.selectedItems.findIndex(x => x === index);

      if (delIndex > -1) {
        this.selectedItems.splice(delIndex, 1);
        this.selectAllChecked = false;
      } else {
        this.selectedItems.push(index);

        if (this.selectedItems.length === this.repo.list.length) {
          this.selectAllChecked = true;
        }
      }
    },
    canDeleteRow(item) {
      return item && item.canDelete && !this.isDeleteDisabled;
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
              v-if="canDeleteRepo"
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
              v-if="canDeleteRepo"
              v-gl-tooltip
              v-gl-modal="modalId"
              :disabled="!selectedItems || selectedItems.length === 0"
              class="js-delete-registry float-right"
              data-track-event="click_button"
              data-track-label="bulk_registry_tag_delete"
              variant="danger"
              :title="s__('ContainerRegistry|Remove selected tags')"
              :aria-label="s__('ContainerRegistry|Remove selected tags')"
              @click="deleteMultipleItems()"
            >
              <icon name="remove" />
            </gl-button>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(item, index) in repo.list" :key="item.tag" class="registry-image-row">
          <td class="check">
            <gl-form-checkbox
              v-if="canDeleteRow(item)"
              class="js-select-checkbox"
              :checked="selectedItems && selectedItems.includes(index)"
              @change="updateselectedItems(index)"
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
            <span v-gl-tooltip.bottom class="monospace" :title="item.revision">{{
              item.shortRevision
            }}</span>
          </td>
          <td>
            {{ formatSize(item.size) }}
            <template v-if="item.size && item.layers"
              >&middot;</template
            >
            {{ layers(item) }}
          </td>

          <td>
            <span v-gl-tooltip.bottom :title="tooltipTitle(item.createdAt)">{{
              timeFormated(item.createdAt)
            }}</span>
          </td>

          <td class="content action-buttons">
            <gl-button
              v-if="canDeleteRow(item)"
              v-gl-modal="modalId"
              :title="s__('ContainerRegistry|Remove tag')"
              :aria-label="s__('ContainerRegistry|Remove tag')"
              data-track-event="click_button"
              data-track-label="registry_tag_delete"
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
      class="js-registry-pagination"
    />

    <gl-modal ref="deleteModal" :modal-id="modalId" ok-variant="danger">
      <template v-slot:modal-title>{{ modalAction }}</template>
      <template v-slot:modal-ok>{{ modalAction }}</template>
      <p v-html="modalDescription"></p>
    </gl-modal>
  </div>
</template>
