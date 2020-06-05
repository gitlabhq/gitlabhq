<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlTable,
  GlFormCheckbox,
  GlDeprecatedButton,
  GlIcon,
  GlTooltipDirective,
  GlPagination,
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
import DeleteAlert from '../components/details_page/delete_alert.vue';
import DeleteModal from '../components/details_page/delete_modal.vue';
import DetailsHeader from '../components/details_page/details_header.vue';
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
  REMOVE_TAGS_BUTTON_TITLE,
  REMOVE_TAG_BUTTON_TITLE,
  EMPTY_IMAGE_REPOSITORY_TITLE,
  EMPTY_IMAGE_REPOSITORY_MESSAGE,
  ALERT_SUCCESS_TAG,
  ALERT_DANGER_TAG,
  ALERT_SUCCESS_TAGS,
  ALERT_DANGER_TAGS,
} from '../constants/index';

export default {
  components: {
    DeleteAlert,
    DetailsHeader,
    GlTable,
    GlFormCheckbox,
    GlDeprecatedButton,
    GlIcon,
    ClipboardButton,
    GlPagination,
    DeleteModal,
    GlSkeletonLoader,
    GlEmptyState,
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
    REMOVE_TAGS_BUTTON_TITLE,
    REMOVE_TAG_BUTTON_TITLE,
    EMPTY_IMAGE_REPOSITORY_TITLE,
    EMPTY_IMAGE_REPOSITORY_MESSAGE,
  },
  data() {
    return {
      selectedItems: [],
      itemsToBeDeleted: [],
      selectAllChecked: false,
      modalDescription: null,
      isDesktop: true,
      deleteAlertType: null,
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
      const tagInnerClass = this.isDesktop ? 'mw-m' : 'gl-justify-content-end';
      return [
        { key: LIST_KEY_CHECKBOX, label: '', class: 'gl-w-16' },
        {
          key: LIST_KEY_TAG,
          label: LIST_LABEL_TAG,
          class: `${tagClass} js-tag-column`,
          innerClass: tagInnerClass,
        },
        { key: LIST_KEY_IMAGE_ID, label: LIST_LABEL_IMAGE_ID },
        { key: LIST_KEY_SIZE, label: LIST_LABEL_SIZE },
        { key: LIST_KEY_LAST_UPDATED, label: LIST_LABEL_LAST_UPDATED },
        { key: LIST_KEY_ACTIONS, label: '' },
      ].filter(f => f.key !== LIST_KEY_CHECKBOX || this.isDesktop);
    },
    tracking() {
      return {
        label:
          this.itemsToBeDeleted?.length > 1 ? 'bulk_registry_tag_delete' : 'registry_tag_delete',
      };
    },
    currentPage: {
      get() {
        return this.tagsPagination.page;
      },
      set(page) {
        this.requestTagsList({ pagination: { page }, params: this.$route.params.id });
      },
    },
  },
  mounted() {
    this.requestTagsList({ params: this.$route.params.id });
  },
  methods: {
    ...mapActions(['requestTagsList', 'requestDeleteTag', 'requestDeleteTags']),
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
      this.selectedItems = this.tags.map(x => x.name);
      this.selectAllChecked = true;
    },
    deselectAll() {
      this.selectedItems = [];
      this.selectAllChecked = false;
    },
    updateSelectedItems(name) {
      const delIndex = this.selectedItems.findIndex(x => x === name);

      if (delIndex > -1) {
        this.selectedItems.splice(delIndex, 1);
        this.selectAllChecked = false;
      } else {
        this.selectedItems.push(name);

        if (this.selectedItems.length === this.tags.length) {
          this.selectAllChecked = true;
        }
      }
    },
    deleteSingleItem(name) {
      this.itemsToBeDeleted = [{ ...this.tags.find(t => t.name === name) }];
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    deleteMultipleItems() {
      this.itemsToBeDeleted = this.selectedItems.map(name => ({
        ...this.tags.find(t => t.name === name),
      }));
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    handleSingleDelete() {
      const [itemToDelete] = this.itemsToBeDeleted;
      this.itemsToBeDeleted = [];
      this.selectedItems = this.selectedItems.filter(name => name !== itemToDelete.name);
      return this.requestDeleteTag({ tag: itemToDelete, params: this.$route.params.id })
        .then(() => {
          this.deleteAlertType = ALERT_SUCCESS_TAG;
        })
        .catch(() => {
          this.deleteAlertType = ALERT_DANGER_TAG;
        });
    },
    handleMultipleDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];
      this.selectedItems = [];

      return this.requestDeleteTags({
        ids: itemsToBeDeleted.map(x => x.name),
        params: this.$route.params.id,
      })
        .then(() => {
          this.deleteAlertType = ALERT_SUCCESS_TAGS;
        })
        .catch(() => {
          this.deleteAlertType = ALERT_DANGER_TAGS;
        });
    },
    onDeletionConfirmed() {
      this.track('confirm_delete');
      if (this.itemsToBeDeleted.length > 1) {
        this.handleMultipleDelete();
      } else {
        this.handleSingleDelete();
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
    <delete-alert
      v-model="deleteAlertType"
      :garbage-collection-help-page-path="config.garbageCollectionHelpPagePath"
      :is-admin="config.isAdmin"
      class="my-2"
    />

    <details-header :image-name="imageName" />

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

      <template #cell(checkbox)="{item}">
        <gl-form-checkbox
          ref="rowCheckbox"
          class="js-row-checkbox"
          :checked="selectedItems.includes(item.name)"
          @change="updateSelectedItems(item.name)"
        />
      </template>
      <template #cell(name)="{item, field}">
        <div ref="rowName" :class="[field.innerClass, 'gl-display-flex']">
          <span
            v-gl-tooltip
            data-testid="rowNameText"
            :title="item.name"
            class="gl-text-overflow-ellipsis gl-overflow-hidden gl-white-space-nowrap"
          >
            {{ item.name }}
          </span>
          <clipboard-button
            v-if="item.location"
            ref="rowClipboardButton"
            :title="item.location"
            :text="item.location"
            css-class="btn-default btn-transparent btn-clipboard"
          />
        </div>
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
      <template #cell(actions)="{item}">
        <gl-deprecated-button
          ref="singleDeleteButton"
          :title="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
          :aria-label="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
          :disabled="!item.destroy_path"
          variant="danger"
          class="js-delete-registry float-right btn-inverted btn-border-color btn-icon"
          @click="deleteSingleItem(item.name)"
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

    <delete-modal
      ref="deleteModal"
      :items-to-be-deleted="itemsToBeDeleted"
      @confirmDelete="onDeletionConfirmed"
      @cancel="track('cancel_delete')"
    />
  </div>
</template>
