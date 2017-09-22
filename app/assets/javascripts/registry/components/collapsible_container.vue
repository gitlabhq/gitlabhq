<script>
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tablePagination from '../../vue_shared/components/table_pagination.vue';
  import tooltip from '../../vue_shared/directives/tooltip';
  import timeagoMixin from '../../vue_shared/mixins/timeago';

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
      layers(item) {
        const pluralize = gl.text.pluralize('layer', item.layers);
        return `${item.layers} ${pluralize}`;
      },

      toggleRepo() {
        if (this.isOpen === false) {
          this.$emit('fetchRegistryList', this.repo);
        }
        this.isOpen = !this.isOpen;
      },

      handleDeleteRepository() {
        this.$emit('deleteRepository', this.repo);
      },

      handleDeleteRegistry(registry) {
        this.$emit('deleteRegistry', this.repo, registry);
      },

      onPageChange(pageNumber) {
        this.$emit('pageChange', this.repo, pageNumber);
      },
    },
  };
</script>

<template>
  <div class="container-image">
    <div
      class="container-image-head">
      <a
        role="button"
        @click="toggleRepo"
        class="js-toggle-repo">
        <i
          class="fa"
          :class="{
            'fa-chevron-right': !isOpen,
            'fa-chevron-up': isOpen,
          }"
          aria-hidden="true">
        </i>
        {{repo.name}}
      </a>

      <clipboard-button
        v-if="repo.location"
        :text="__(`docker pull ${repo.location}`)"
        :title="repo.location"
        />

      <div class="controls hidden-xs pull-right">
        <button
          v-if="repo.canDelete"
          type="button"
          class="js-remove-repo btn btn-remove"
          :title="__('Remove repository')"
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
              <th>{{__("Tag")}}</th>
              <th>{{__("Tag ID")}}</th>
              <th>{{__("Size")}}</th>
              <th>{{__("Created")}}</th>
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
                  :text="__(`docker pull ${item.location}`)"
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
                  class="js-delete-registry btn btn-remove hidden-xs pull-right"
                  :title="__('Remove tag')"
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
        {{__("No tags in Container Registry for this container image.")}}
      </div>
    </div>
  </div>
</template>
