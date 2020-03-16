<script>
import { mapState, mapActions } from 'vuex';
import {
  GlEmptyState,
  GlPagination,
  GlTooltipDirective,
  GlButton,
  GlIcon,
  GlModal,
  GlSprintf,
  GlLink,
  GlSkeletonLoader,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ProjectEmptyState from '../components/project_empty_state.vue';
import GroupEmptyState from '../components/group_empty_state.vue';
import ProjectPolicyAlert from '../components/project_policy_alert.vue';

export default {
  name: 'RegistryListApp',
  components: {
    GlEmptyState,
    GlPagination,
    ProjectEmptyState,
    GroupEmptyState,
    ProjectPolicyAlert,
    ClipboardButton,
    GlButton,
    GlIcon,
    GlModal,
    GlSprintf,
    GlLink,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  data() {
    return {
      itemToDelete: {},
    };
  },
  computed: {
    ...mapState(['config', 'isLoading', 'images', 'pagination']),
    tracking() {
      return {
        label: 'registry_repository_delete',
      };
    },
    currentPage: {
      get() {
        return this.pagination.page;
      },
      set(page) {
        this.requestImagesList({ page });
      },
    },
  },
  methods: {
    ...mapActions(['requestImagesList', 'requestDeleteImage']),
    deleteImage(item) {
      // This event is already tracked in the system and so the name must be kept to aggregate the data
      this.track('click_button');
      this.itemToDelete = item;
      this.$refs.deleteModal.show();
    },
    handleDeleteRepository() {
      this.track('confirm_delete');
      this.requestDeleteImage(this.itemToDelete.destroy_path);
      this.itemToDelete = {};
    },
    encodeListItem(item) {
      const params = JSON.stringify({ name: item.path, tags_path: item.tags_path, id: item.id });
      return window.btoa(params);
    },
  },
};
</script>

<template>
  <div class="w-100 slide-enter-from-element">
    <project-policy-alert v-if="!config.isGroupPage" />

    <gl-empty-state
      v-if="config.characterError"
      :title="s__('ContainerRegistry|Docker connection error')"
      :svg-path="config.containersErrorImage"
    >
      <template #description>
        <p>
          <gl-sprintf
            :message="
              s__(`ContainerRegistry|We are having trouble connecting to Docker, which could be due to an
            issue with your project name or path.
            %{docLinkStart}More Information%{docLinkEnd}`)
            "
          >
            <template #docLink="{content}">
              <gl-link :href="`${config.helpPagePath}#docker-connection-error`" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </gl-empty-state>

    <template v-else>
      <div>
        <h4>{{ s__('ContainerRegistry|Container Registry') }}</h4>
        <p>
          <gl-sprintf
            :message="
              s__(`ContainerRegistry|With the Docker Container Registry integrated into GitLab, every
            project can have its own space to store its Docker images.
            %{docLinkStart}More Information%{docLinkEnd}`)
            "
          >
            <template #docLink="{content}">
              <gl-link :href="config.helpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>

      <div v-if="isLoading" class="mt-2">
        <gl-skeleton-loader
          v-for="index in $options.loader.repeat"
          :key="index"
          :width="$options.loader.width"
          :height="$options.loader.height"
          preserve-aspect-ratio="xMinYMax meet"
        >
          <rect width="500" x="10" y="10" height="20" rx="4" />
          <circle cx="525" cy="20" r="10" />
          <rect x="960" y="0" width="40" height="40" rx="4" />
        </gl-skeleton-loader>
      </div>
      <template v-else>
        <div v-if="images.length" ref="imagesList" class="d-flex flex-column">
          <div
            v-for="(listItem, index) in images"
            :key="index"
            ref="rowItem"
            :class="{ 'border-top': index === 0 }"
            class="d-flex justify-content-between align-items-center py-2 border-bottom"
          >
            <div>
              <router-link
                ref="detailsLink"
                :to="{ name: 'details', params: { id: encodeListItem(listItem) } }"
              >
                {{ listItem.path }}
              </router-link>
              <clipboard-button
                v-if="listItem.location"
                ref="clipboardButton"
                :text="listItem.location"
                :title="listItem.location"
                css-class="btn-default btn-transparent btn-clipboard"
              />
            </div>
            <div
              v-gl-tooltip="{ disabled: listItem.destroy_path }"
              class="d-none d-sm-block"
              :title="
                s__('ContainerRegistry|Missing or insufficient permission, delete button disabled')
              "
            >
              <gl-button
                ref="deleteImageButton"
                v-gl-tooltip
                :disabled="!listItem.destroy_path"
                :title="s__('ContainerRegistry|Remove repository')"
                :aria-label="s__('ContainerRegistry|Remove repository')"
                class="btn-inverted"
                variant="danger"
                @click="deleteImage(listItem)"
              >
                <gl-icon name="remove" />
              </gl-button>
            </div>
          </div>
          <gl-pagination
            v-model="currentPage"
            :per-page="pagination.perPage"
            :total-items="pagination.total"
            align="center"
            class="w-100 mt-2"
          />
        </div>

        <template v-else>
          <project-empty-state v-if="!config.isGroupPage" />
          <group-empty-state v-else />
        </template>
      </template>

      <gl-modal
        ref="deleteModal"
        modal-id="delete-image-modal"
        ok-variant="danger"
        @ok="handleDeleteRepository"
        @cancel="track('cancel_delete')"
      >
        <template #modal-title>{{ s__('ContainerRegistry|Remove repository') }}</template>
        <p>
          <gl-sprintf
            :message=" s__(
                'ContainerRegistry|You are about to remove repository %{title}. Once you confirm, this repository will be permanently deleted.',
              ),"
          >
            <template #title>
              <b>{{ itemToDelete.path }}</b>
            </template>
          </gl-sprintf>
        </p>
        <template #modal-ok>{{ __('Remove') }}</template>
      </gl-modal>
    </template>
  </div>
</template>
