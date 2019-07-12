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
      singleItemToBeDeleted: null,
      itemsToBeDeleted: [],
      modalId: `confirm-image-deletion-modal-${this.repo.id}`,
      selectAllChecked: false,
    };
  },
  computed: {
    shouldRenderPagination() {
      return this.repo.pagination.total > this.repo.pagination.perPage;
    },
    modalTitle() {
      if (this.singleItemToBeDeleted !== null || this.itemsToBeDeleted.length === 1) {
        return s__('ContainerRegistry|Remove image');
      }
      return s__('ContainerRegistry|Remove images');
    },
    modalDescription() {
      const selectedCount = this.itemsToBeDeleted.length;

      if (this.singleItemToBeDeleted !== null || selectedCount === 1) {
        const { tag } =
          this.singleItemToBeDeleted !== null
            ? this.repo.list[this.singleItemToBeDeleted]
            : this.repo.list[this.itemsToBeDeleted[0]];

        return sprintf(
          s__(`ContainerRegistry|You are about to delete the image <b>%{title}</b>. This will
          delete the image and all tags pointing to this image.`),
          { title: `${this.repo.name}:${tag}` },
        );
      }

      return sprintf(
        s__(`ContainerRegistry|You are about to delete <b>%{count}</b> images. This will
          delete the images and all tags pointing to them.`),
        { count: selectedCount },
      );
    },
  },
  methods: {
    ...mapActions(['fetchList', 'deleteItem']),
    layers(item) {
      return item.layers ? n__('%d layer', '%d layers', item.layers) : '';
    },
    formatSize(size) {
      return numberToHumanSize(size);
    },
    setSingleItemToBeDeleted(idx) {
      this.singleItemToBeDeleted = idx;
    },
    resetSingleItemToBeDeleted() {
      this.singleItemToBeDeleted = null;
    },
    handleDeleteRegistry() {
      let { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];

      if (this.singleItemToBeDeleted !== null) {
        const { singleItemToBeDeleted } = this;
        this.singleItemToBeDeleted = null;
        itemsToBeDeleted = [singleItemToBeDeleted];
      }

      const deleteActions = itemsToBeDeleted.map(
        x =>
          new Promise((resolve, reject) => {
            this.deleteItem(this.repo.list[x])
              .then(resolve)
              .catch(reject);
          }),
      );

      Promise.all(deleteActions)
        .then(() => this.fetchList({ repo: this.repo }))
        .catch(() => this.showError(errorMessagesTypes.DELETE_REGISTRY));
    },
    onPageChange(pageNumber) {
      this.fetchList({ repo: this.repo, page: pageNumber }).catch(() =>
        this.showError(errorMessagesTypes.FETCH_REGISTRY),
      );
    },
    showError(message) {
      createFlash(errorMessages[message]);
    },
    selectAll() {
      if (!this.selectAllChecked) {
        this.itemsToBeDeleted = this.repo.list.map((x, idx) => idx);
        this.selectAllChecked = true;
      } else {
        this.itemsToBeDeleted = [];
        this.selectAllChecked = false;
      }
    },
    updateItemsToBeDeleted(idx) {
      const delIdx = this.itemsToBeDeleted.findIndex(x => x === idx);

      if (delIdx > -1) {
        this.itemsToBeDeleted.splice(delIdx, 1);
        this.selectAllChecked = false;
      } else {
        this.itemsToBeDeleted.push(idx);

        if (this.itemsToBeDeleted.length === this.repo.list.length) {
          this.selectAllChecked = true;
        }
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
              @change="selectAll"
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
              ><icon name="remove"
            /></gl-button>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(item, idx) in repo.list" :key="item.tag">
          <td class="check">
            <gl-form-checkbox
              v-if="item.canDelete"
              class="js-select-checkbox"
              :checked="itemsToBeDeleted && itemsToBeDeleted.includes(idx)"
              @change="updateItemsToBeDeleted(idx)"
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
              @click="setSingleItemToBeDeleted(idx)"
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

    <gl-modal
      :modal-id="modalId"
      ok-variant="danger"
      @ok="handleDeleteRegistry"
      @cancel="resetSingleItemToBeDeleted"
    >
      <template v-slot:modal-title>{{ modalTitle }}</template>
      <template v-slot:modal-ok>{{ s__('ContainerRegistry|Remove image(s) and tags') }}</template>
      <p v-html="modalDescription"></p>
    </gl-modal>
  </div>
</template>
