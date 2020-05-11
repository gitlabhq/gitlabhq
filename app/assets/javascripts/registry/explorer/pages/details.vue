<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlTable,
  GlFormCheckbox,
  GlDeprecatedButton,
  GlIcon,
  GlTooltipDirective,
  GlPagination,
  GlModal,
  GlSprintf,
  GlAlert,
  GlLink,
  GlEmptyState,
  GlResizeObserverDirective,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import Tracking from '~/tracking';
import { decodeAndParse } from '../utils';
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
  DELETE_TAG_SUCCESS_MESSAGE,
  DELETE_TAG_ERROR_MESSAGE,
  DELETE_TAGS_SUCCESS_MESSAGE,
  DELETE_TAGS_ERROR_MESSAGE,
  REMOVE_TAG_CONFIRMATION_TEXT,
  REMOVE_TAGS_CONFIRMATION_TEXT,
  DETAILS_PAGE_TITLE,
  REMOVE_TAGS_BUTTON_TITLE,
  REMOVE_TAG_BUTTON_TITLE,
  EMPTY_IMAGE_REPOSITORY_TITLE,
  EMPTY_IMAGE_REPOSITORY_MESSAGE,
  ADMIN_GARBAGE_COLLECTION_TIP,
} from '../constants';

export default {
  components: {
    GlTable,
    GlFormCheckbox,
    GlDeprecatedButton,
    GlIcon,
    ClipboardButton,
    GlPagination,
    GlModal,
    GlSkeletonLoader,
    GlSprintf,
    GlEmptyState,
    GlAlert,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [timeagoMixin, Tracking.mixin()],
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  i18n: {
    DETAILS_PAGE_TITLE,
    REMOVE_TAGS_BUTTON_TITLE,
    REMOVE_TAG_BUTTON_TITLE,
    EMPTY_IMAGE_REPOSITORY_TITLE,
    EMPTY_IMAGE_REPOSITORY_MESSAGE,
  },
  alertMessages: {
    success_tag: DELETE_TAG_SUCCESS_MESSAGE,
    danger_tag: DELETE_TAG_ERROR_MESSAGE,
    success_tags: DELETE_TAGS_SUCCESS_MESSAGE,
    danger_tags: DELETE_TAGS_ERROR_MESSAGE,
  },
  data() {
    return {
      selectedItems: [],
      itemsToBeDeleted: [],
      selectAllChecked: false,
      modalDescription: null,
      isDesktop: true,
      deleteAlertType: false,
    };
  },
  computed: {
    ...mapGetters(['tags']),
    ...mapState(['tagsPagination', 'isLoading', 'config']),
    imageName() {
      const { name } = decodeAndParse(this.$route.params.id);
      return name;
    },
    fields() {
      const tagClass = this.isDesktop ? 'w-25' : '';
      return [
        { key: LIST_KEY_CHECKBOX, label: '', class: 'gl-w-16' },
        { key: LIST_KEY_TAG, label: LIST_LABEL_TAG, class: `${tagClass} js-tag-column` },
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
        this.requestTagsList({ pagination: { page }, params: this.$route.params.id });
      },
    },
    deleteAlertConfig() {
      const config = {
        title: '',
        message: '',
        type: 'success',
      };
      if (this.deleteAlertType) {
        [config.type] = this.deleteAlertType.split('_');

        const defaultMessage = this.$options.alertMessages[this.deleteAlertType];

        if (this.config.isAdmin && config.type === 'success') {
          config.title = defaultMessage;
          config.message = ADMIN_GARBAGE_COLLECTION_TIP;
        } else {
          config.message = defaultMessage;
        }
      }
      return config;
    },
  },
  mounted() {
    this.requestTagsList({ params: this.$route.params.id });
  },
  methods: {
    ...mapActions(['requestTagsList', 'requestDeleteTag', 'requestDeleteTags']),
    setModalDescription(itemIndex = -1) {
      if (itemIndex === -1) {
        this.modalDescription = {
          message: REMOVE_TAGS_CONFIRMATION_TEXT,
          item: this.itemsToBeDeleted.length,
        };
      } else {
        const { path } = this.tags[itemIndex];

        this.modalDescription = {
          message: REMOVE_TAG_CONFIRMATION_TEXT,
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
    handleSingleDelete(index) {
      const itemToDelete = this.tags[index];
      this.itemsToBeDeleted = [];
      this.selectedItems = this.selectedItems.filter(i => i !== index);
      return this.requestDeleteTag({ tag: itemToDelete, params: this.$route.params.id })
        .then(() => {
          this.deleteAlertType = 'success_tag';
        })
        .catch(() => {
          this.deleteAlertType = 'danger_tag';
        });
    },
    handleMultipleDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];
      this.selectedItems = [];

      return this.requestDeleteTags({
        ids: itemsToBeDeleted.map(x => this.tags[x].name),
        params: this.$route.params.id,
      })
        .then(() => {
          this.deleteAlertType = 'success_tags';
        })
        .catch(() => {
          this.deleteAlertType = 'danger_tags';
        });
    },
    onDeletionConfirmed() {
      this.track('confirm_delete');
      if (this.isMultiDelete) {
        this.handleMultipleDelete();
      } else {
        this.handleSingleDelete(this.itemsToBeDeleted[0]);
      }
    },
    handleResize() {
      this.isDesktop = GlBreakpointInstance.isDesktop();
    },
  },
};
</script>

<template>
  <div v-gl-resize-observer="handleResize" class="my-3 w-100 slide-enter-to-element">
    <gl-alert
      v-if="deleteAlertType"
      :variant="deleteAlertConfig.type"
      :title="deleteAlertConfig.title"
      class="my-2"
      @dismiss="deleteAlertType = null"
    >
      <gl-sprintf :message="deleteAlertConfig.message">
        <template #docLink="{content}">
          <gl-link :href="config.garbageCollectionHelpPagePath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <div class="d-flex my-3 align-items-center">
      <h4>
        <gl-sprintf :message="$options.i18n.DETAILS_PAGE_TITLE">
          <template #imageName>
            {{ imageName }}
          </template>
        </gl-sprintf>
      </h4>
    </div>

    <gl-table :items="tags" :fields="fields" :stacked="!isDesktop" show-empty>
      <template v-if="isDesktop" #head(checkbox)>
        <gl-form-checkbox
          ref="mainCheckbox"
          :checked="selectAllChecked"
          @change="onSelectAllChange"
        />
      </template>
      <template #head(actions)>
        <gl-deprecated-button
          ref="bulkDeleteButton"
          v-gl-tooltip
          :disabled="!selectedItems || selectedItems.length === 0"
          class="float-right"
          variant="danger"
          :title="$options.i18n.REMOVE_TAGS_BUTTON_TITLE"
          :aria-label="$options.i18n.REMOVE_TAGS_BUTTON_TITLE"
          @click="deleteMultipleItems()"
        >
          <gl-icon name="remove" />
        </gl-deprecated-button>
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
        <span ref="rowTime" v-gl-tooltip :title="tooltipTitle(value)">
          {{ timeFormatted(value) }}
        </span>
      </template>
      <template #cell(actions)="{index, item}">
        <gl-deprecated-button
          ref="singleDeleteButton"
          :title="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
          :aria-label="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
          :disabled="!item.destroy_path"
          variant="danger"
          class="js-delete-registry float-right btn-inverted btn-border-color btn-icon"
          @click="deleteSingleItem(index)"
        >
          <gl-icon name="remove" />
        </gl-deprecated-button>
      </template>

      <template #empty>
        <template v-if="isLoading">
          <gl-skeleton-loader
            v-for="index in $options.loader.repeat"
            :key="index"
            :width="$options.loader.width"
            :height="$options.loader.height"
            preserve-aspect-ratio="xMinYMax meet"
          >
            <rect width="15" x="0" y="12.5" height="15" rx="4" />
            <rect width="250" x="25" y="10" height="20" rx="4" />
            <circle cx="290" cy="20" r="10" />
            <rect width="100" x="315" y="10" height="20" rx="4" />
            <rect width="100" x="500" y="10" height="20" rx="4" />
            <rect width="100" x="630" y="10" height="20" rx="4" />
            <rect x="960" y="0" width="40" height="40" rx="4" />
          </gl-skeleton-loader>
        </template>
        <gl-empty-state
          v-else
          :title="$options.i18n.EMPTY_IMAGE_REPOSITORY_TITLE"
          :svg-path="config.noContainersImage"
          :description="$options.i18n.EMPTY_IMAGE_REPOSITORY_MESSAGE"
          class="mx-auto my-0"
        />
      </template>
    </gl-table>

    <gl-pagination
      v-if="!isLoading"
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
  </div>
</template>
