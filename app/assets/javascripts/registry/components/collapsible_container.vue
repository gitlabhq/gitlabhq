<script>
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';

  export default {
    name: 'collapsibeContainerRegisty',
    props: {
      title: {
        type: String,
        required: true,
      },
      clipboardContent: {
        type: String,
        required: true,
      },
      repoData: {
        type: Object,
        required: true,
      },
    },
    components: {
      clipboardButton,
    },
    data() {
      return {
        isOpen: false,
      };
    },
    methods: {
      itemSize(item) {
        const pluralize = gl.text.pluralize('layer', item.layers);
        return `${item.size}&middot;${item.layers}${pluralize}`;
      }
    }
  }
</script>

<template>
  <div class="container-image">
    <div class="container-image-head">
      <i
        class="fa"
        :class="{
          'chevron-left': !isOpen,
          'chevron-up': isOpen,
        }"
        aria-hidden="true">
      </i>
      {{title}}

      <clipboard-button
        :text=""
        :title=""
      />
    </div>
    <div
      class="container-image-tags"
      :class="{ hide: !isOpen }">

      <table class="table tags" v-if="true">
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
              {{item.name}}
              <clipboard-button
                :title="item.location"
                :text="item.location"
                />
            </td>
            <td>
              <span
                v-tooltip
                :title="item.revision"
                >
                {{item.shortRevision}}
                </span>
            </td>
            <td>
              <template v-if="item.size">
                {{itemSize(item)}}
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

            <td>
              <button
                type="button"
                class="btn btn-remove"
                title="Remove tag"
                v-tooltip
                @click="deleteTag(item)">
                <i
                  class="fa fa-trash cred"
                  aria-hidden="true">
                </i>
              </button>
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
