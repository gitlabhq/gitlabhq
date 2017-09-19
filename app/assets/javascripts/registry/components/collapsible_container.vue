<script>
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

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
    },
    directives: {
      tooltip,
    },
    data() {
      return {
        isOpen: false,
      };
    },
    methods: {
      layers(item) {
        const pluralize = gl.text.pluralize('layer', item.layers);
        return `${item.layers} ${pluralize}`;
      },
      toggleRepo() {
        if (this.isOpen === false) {
          // consider not fetching data the second time it is toggled? :fry:
          this.$emit('fetchRegistryList', this.repo);
        }
        this.isOpen = !this.isOpen;
      },
      handleDeleteRepository() {
        this.$emit('deleteRepository', this.repo)
      },
      handleDeleteRegistry(registry) {
        this.$emit('deleteRegistry', this.repo, registry);
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
        @click="toggleRepo">
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

      <clipboard-button text="foo" title="bar" />

      <div class="controls hidden-xs pull-right">
        <button
          v-if="repo.canDelete"
          type="button"
          class="btn btn-remove"
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

      <table class="table tags" v-if="repo.list.length">
        <thead>
          <tr>
            <th>{{__("Tag")}}</th>
            <th>{{__("Tag ID")}}</th>
            <th>{{__("Size")}}</th>
            <th>{{__("Created")}}</th>
            <th v-if="true"></th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="(item, i) in repo.list"
            :key="i">
            <td>

              {{item.tag}}

              <clipboard-button
                :title="item.tag"
                :text="item.tag"
                />
            </td>
            <td>
              <span
                v-tooltip
                :title="item.revision"
                data-placement="bottom"
                >
                {{item.shortRevision}}
                </span>
            </td>
            <td>
              <template v-if="item.size">
                {{item.size}}
                &middot;
                {{layers(item)}}
              </template>
              <div v-else class="light">
                \-
              </div>
            </td>

            <td>
              <template v-if="item.createdAt">
                format {{item.createdAt}}
              </template>
              <div v-else class="light">
                \-
              </div>
            </td>

            <td class="content">
              <div class="controls hidden-xs pull-right">
                <button
                  type="button"
                  class="btn btn-remove"
                  title="Remove tag"
                  v-tooltip
                  @click="handleDeleteRegistry(item)">
                  <i
                    class="fa fa-trash"
                    aria-hidden="true">
                  </i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <div
        v-else
        class="nothing-here-block">
        {{__("No tags in Container Registry for this container image.")}}
      </div>
    </div>
  </div>
</template>
