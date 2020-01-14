<script>
import { mapActions, mapGetters } from 'vuex';
import {
  GlLoadingIcon,
  GlButton,
  GlTooltipDirective,
  GlModal,
  GlModalDirective,
  GlEmptyState,
} from '@gitlab/ui';
import createFlash from '~/flash';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import TableRegistry from './table_registry.vue';
import { DELETE_REPO_ERROR_MESSAGE } from '../constants';
import { __, sprintf } from '~/locale';

export default {
  name: 'CollapsibeContainerRegisty',
  components: {
    ClipboardButton,
    TableRegistry,
    GlLoadingIcon,
    GlButton,
    Icon,
    GlModal,
    GlEmptyState,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    repo: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isOpen: false,
      modalId: `confirm-repo-deletion-modal-${this.repo.id}`,
      tracking: {
        label: 'registry_repository_delete',
      },
    };
  },
  computed: {
    ...mapGetters(['isDeleteDisabled']),
    iconName() {
      return this.isOpen ? 'angle-up' : 'angle-right';
    },
    canDeleteRepo() {
      return this.repo.canDelete && !this.isDeleteDisabled;
    },
    deleteImageConfirmationMessage() {
      return sprintf(__('Image %{imageName} was scheduled for deletion from the registry.'), {
        imageName: this.repo.name,
      });
    },
  },
  methods: {
    ...mapActions(['fetchRepos', 'fetchList', 'deleteItem']),
    toggleRepo() {
      this.isOpen = !this.isOpen;

      if (this.isOpen) {
        this.fetchList({ repo: this.repo });
      }
    },
    handleDeleteRepository() {
      this.track('confirm_delete');
      return this.deleteItem(this.repo)
        .then(() => {
          createFlash(this.deleteImageConfirmationMessage, 'notice');
          this.fetchRepos();
        })
        .catch(() => createFlash(DELETE_REPO_ERROR_MESSAGE));
    },
  },
};
</script>

<template>
  <div class="container-image">
    <div class="container-image-head">
      <gl-button class="js-toggle-repo btn-link align-baseline" @click="toggleRepo">
        <icon :name="iconName" />
        {{ repo.name }}
      </gl-button>

      <clipboard-button
        v-if="repo.location"
        :text="repo.location"
        :title="repo.location"
        css-class="btn-default btn-transparent btn-clipboard"
      />

      <div class="controls d-none d-sm-block float-right">
        <gl-button
          v-if="canDeleteRepo"
          v-gl-tooltip
          v-gl-modal="modalId"
          :title="s__('ContainerRegistry|Remove repository')"
          :aria-label="s__('ContainerRegistry|Remove repository')"
          class="js-remove-repo btn-inverted"
          variant="danger"
          @click="track('click_button')"
        >
          <icon name="remove" />
        </gl-button>
      </div>
    </div>

    <gl-loading-icon v-if="repo.isLoading" size="md" class="append-bottom-20" />

    <div v-else-if="!repo.isLoading && isOpen" class="container-image-tags">
      <table-registry v-if="repo.list.length" :repo="repo" :can-delete-repo="canDeleteRepo" />
      <gl-empty-state
        v-else
        :title="s__('ContainerRegistry|This image has no active tags')"
        :description="
          s__(
            `ContainerRegistry|The last tag related to this image was recently removed.
            This empty image and any associated data will be automatically removed as part of the regular Garbage Collection process.
            If you have any questions, contact your administrator.`,
          )
        "
        class="mx-auto my-0"
      />
    </div>
    <gl-modal
      ref="deleteModal"
      :modal-id="modalId"
      ok-variant="danger"
      @ok="handleDeleteRepository"
      @cancel="track('cancel_delete')"
    >
      <template v-slot:modal-title>{{ s__('ContainerRegistry|Remove repository') }}</template>
      <p
        v-html="
          sprintf(
            s__(
              'ContainerRegistry|You are about to remove repository <b>%{title}</b>. Once you confirm, this repository will be permanently deleted.',
            ),
            { title: repo.name },
          )
        "
      ></p>
      <template v-slot:modal-ok>{{ __('Remove') }}</template>
    </gl-modal>
  </div>
</template>
