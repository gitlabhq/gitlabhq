<script>
  import { mapActions } from 'vuex';
  import { n__, s__ } from '../../locale';
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import tablePagination from '../../vue_shared/components/table_pagination.vue';
  import tooltip from '../../vue_shared/directives/tooltip';
  import timeagoMixin from '../../vue_shared/mixins/timeago';
  import { errorMessages, errorMessagesTypes } from '../constants';

  export default {
    props: {
      repo: {
        type: Object,
        required: true,
      },
    },
    components: {
      clipboardButton,
      tablePagination,
    },
    mixins: [
      timeagoMixin,
    ],
    directives: {
      tooltip,
    },
    computed: {
      shouldRenderPagination() {
        return this.repo.pagination.total > this.repo.pagination.perPage;
      },
    },
    methods: {
      ...mapActions([
        'fetchList',
        'deleteRegistry',
      ]),

      layers(item) {
        const pluralize = n__('layer', 'layers', item.layers);
        return `${item.layers} ${pluralize}`;
      },
       handleDeleteRegistry(registry) {
        this.deleteRegistry(registry)
          .then(() => this.fetchList({ repo: this.repo }))
          .catch(() => this.showError(errorMessagesTypes.DELETE_REGISTRY));
      },

      onPageChange(pageNumber) {
        this.fetchList({ repo: this.repo, page })
          .catch(() => this.showError(errorMessagesTypes.FETCH_REGISTRY));
      },

      clipboardText(text) {
        return `docker pull ${text}`;
      },

      showError(message) {
        Flash((errorMessages[message]));
      },
    },
  };
</script>
<template>
<div>
  <table class="table tags">
    <thead>
      <tr>
        <th>{{s__('ContainerRegistry|Tag')}}</th>
        <th>{{s__('ContainerRegistry|Tag ID')}}</th>
        <th>{{s__("ContainerRegistry|Size")}}</th>
        <th>{{s__("ContainerRegistry|Created")}}</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <tr
        v-for="(item, i) in repo.list"
        :key="i">
        <td>

          {{item.tag}}

          <clipboard-button
            v-if="item.location"
            :title="item.location"
            :text="clipboardText(item.location)"
            />
        </td>
        <td>
          <span
            v-tooltip
            :title="item.revision"
            data-placement="bottom">
            {{item.shortRevision}}
            </span>
        </td>
        <td>
          <template v-if="item.size">
            {{item.size}}
            &middot;
            {{layers(item)}}
          </template>
          <div
            v-else
            class="light">
            \-
          </div>
        </td>

        <td>
          <template v-if="item.createdAt">
            {{timeFormated(item.createdAt)}}
          </template>
          <div
            v-else
            class="light">
            \-
          </div>
        </td>

        <td class="content">
          <button
            v-if="item.canDelete"
            type="button"
            class="js-delete-registry btn btn-danger hidden-xs pull-right"
            :title="s__('ContainerRegistry|Remove tag')"
            :aria-label="s__('ContainerRegistry|Remove tag')"
            data-container="body"
            v-tooltip
            @click="handleDeleteRegistry(item)">
            <i
              class="fa fa-trash"
              aria-hidden="true">
            </i>
          </button>
        </td>
      </tr>
    </tbody>
  </table>

  <table-pagination
    v-if="shouldRenderPagination"
    :change="onPageChange"
    :page-info="repo.pagination"
    />
</div>
</template>
