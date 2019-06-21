<script>
import { mapActions } from 'vuex';
import { GlButton, GlTooltipDirective, GlModal, GlModalDirective } from '@gitlab/ui';
import { n__ } from '../../locale';
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
      itemToBeDeleted: null,
    };
  },
  computed: {
    shouldRenderPagination() {
      return this.repo.pagination.total > this.repo.pagination.perPage;
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
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = item;
    },
    handleDeleteRegistry() {
      const { itemToBeDeleted } = this;
      this.itemToBeDeleted = null;
      this.deleteItem(itemToBeDeleted)
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
  },
};
</script>
<template>
  <div>
    <table class="table tags">
      <thead>
        <tr>
          <th>{{ s__('ContainerRegistry|Tag') }}</th>
          <th>{{ s__('ContainerRegistry|Tag ID') }}</th>
          <th>{{ s__('ContainerRegistry|Size') }}</th>
          <th>{{ s__('ContainerRegistry|Last Updated') }}</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in repo.list" :key="item.tag">
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

          <td class="content">
            <gl-button
              v-if="item.canDelete"
              v-gl-tooltip
              v-gl-modal="'confirm-image-deletion-modal'"
              :title="s__('ContainerRegistry|Remove image')"
              :aria-label="s__('ContainerRegistry|Remove image')"
              variant="danger"
              class="js-delete-registry d-none d-sm-block float-right"
              @click="setItemToBeDeleted(item)"
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
      modal-id="confirm-image-deletion-modal"
      ok-variant="danger"
      @ok="handleDeleteRegistry"
    >
      <template v-slot:modal-title>{{ s__('ContainerRegistry|Remove image') }}</template>
      <template v-slot:modal-ok>{{ s__('ContainerRegistry|Remove image and tags') }}</template>
      <p
        v-html="
          sprintf(
            s__(
              'ContainerRegistry|You are about to delete the image <b>%{title}</b>. This will delete the image and all tags pointing to this image.',
            ),
            { title: repo.name },
          )
        "
      ></p>
    </gl-modal>
  </div>
</template>
