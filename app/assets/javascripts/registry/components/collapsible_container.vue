<script>
  import { mapActions } from 'vuex';
  import { n__, s__ } from '../../locale';
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tablePagination from '../../vue_shared/components/table_pagination.vue';
  import tooltip from '../../vue_shared/directives/tooltip';
  import timeagoMixin from '../../vue_shared/mixins/timeago';
  import { errorMessages, errorMessagesTypes } from '../constants';

  export default {
    name: 'collapsibeContainerRegisty',
    props: {
      repo: {
        type: Object,
        required: true,
      },
    },
    components: {
      clipboardButton,
      loadingIcon,
      tablePagination,
    },
    mixins: [
      timeagoMixin,
    ],
    directives: {
      tooltip,
    },
    data() {
      return {
        isOpen: false,
      };
    },
    computed: {
      shouldRenderPagination() {
        return this.repo.pagination.total > this.repo.pagination.perPage;
      },
    },
    methods: {
      ...mapActions([
        'fetchList',
        'deleteRepo',
        'deleteRegistry',
        'toggleLoading',
      ]),

      layers(item) {
        const pluralize = n__('layer', 'layers', item.layers);
        return `${item.layers} ${pluralize}`;
      },

      toggleRepo() {
        if (this.isOpen === false) {
          this.fetchList({ repo: this.repo })
          .catch(() => this.showError(errorMessagesTypes.FETCH_REGISTRY));
        }
        this.isOpen = !this.isOpen;
      },

      handleDeleteRepository() {
        this.deleteRepo(this.repo)
          .then(() => this.fetchRepos())
          .catch(() => this.showError(errorMessagesTypes.DELETE_REPO));
      },

      handleDeleteRegistry(registry) {
        this.deleteRegistry(registry)
          .then(() => this.fetchRegistry(this.repo))
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
  <div class="container-image">
    <div
      class="container-image-head">
      <button
        type="button"
        @click="toggleRepo"
        class="js-toggle-repo btn-link">
        <i
          class="fa"
          :class="{
            'fa-chevron-right': !isOpen,
            'fa-chevron-up': isOpen,
          }"
          aria-hidden="true">
        </i>
        {{repo.name}}
      </button>

      <clipboard-button
        v-if="repo.location"
        :text="clipboardText(repo.location)"
        :title="repo.location"
        />

      <div class="controls hidden-xs pull-right">
        <button
          v-if="repo.canDelete"
          type="button"
          class="js-remove-repo btn btn-danger"
          :title="s__('ContainerRegistry|Remove repository')"
          :aria-label="s__('ContainerRegistry|Remove repository')"
          v-tooltip
          @click="handleDeleteRepository">
          <i
            class="fa fa-trash"
            aria-hidden="true">
          </i>
        </button>
      </div>

    </div>

    <loading-icon
      v-if="repo.isLoading"
      />

    <div
      v-else-if="!repo.isLoading && isOpen"
      class="container-image-tags">

      <template v-if="repo.list.length">
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
      </template>
      <div
        v-else
        class="nothing-here-block">
        {{s__("ContainerRegistry|No tags in Container Registry for this container image.")}}
      </div>
    </div>
  </div>
</template>
