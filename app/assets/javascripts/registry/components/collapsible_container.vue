<script>
import { mapActions } from 'vuex';
import { GlLoadingIcon, GlButton, GlTooltipDirective, GlModal, GlModalDirective } from '@gitlab/ui';
import createFlash from '../../flash';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import Icon from '../../vue_shared/components/icon.vue';
import TableRegistry from './table_registry.vue';
import { errorMessages, errorMessagesTypes } from '../constants';
import { __ } from '../../locale';

export default {
  name: 'CollapsibeContainerRegisty',
  components: {
    ClipboardButton,
    TableRegistry,
    GlLoadingIcon,
    GlButton,
    Icon,
    GlModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
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
    };
  },
  computed: {
    iconName() {
      return this.isOpen ? 'angle-up' : 'angle-right';
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
      this.deleteItem(this.repo)
        .then(() => {
          createFlash(__('This container registry has been scheduled for deletion.'), 'notice');
          this.fetchRepos();
        })
        .catch(() => this.showError(errorMessagesTypes.DELETE_REPO));
    },
    showError(message) {
      createFlash(errorMessages[message]);
    },
  },
};
</script>

<template>
  <div class="container-image">
    <div class="container-image-head">
      <gl-button class="js-toggle-repo btn-link align-baseline" @click="toggleRepo">
        <icon :name="iconName" /> {{ repo.name }}
      </gl-button>

      <clipboard-button
        v-if="repo.location"
        :text="repo.location"
        :title="repo.location"
        css-class="btn-default btn-transparent btn-clipboard"
      />

      <div class="controls d-none d-sm-block float-right">
        <gl-button
          v-if="repo.canDelete"
          v-gl-tooltip
          v-gl-modal="modalId"
          :title="s__('ContainerRegistry|Remove repository')"
          :aria-label="s__('ContainerRegistry|Remove repository')"
          class="js-remove-repo btn-inverted"
          variant="danger"
        >
          <icon name="remove" />
        </gl-button>
      </div>
    </div>

    <gl-loading-icon v-if="repo.isLoading" size="md" class="append-bottom-20" />

    <div v-else-if="!repo.isLoading && isOpen" class="container-image-tags">
      <table-registry v-if="repo.list.length" :repo="repo" />

      <div v-else class="nothing-here-block">
        {{ s__('ContainerRegistry|No tags in Container Registry for this container image.') }}
      </div>
    </div>
    <gl-modal :modal-id="modalId" ok-variant="danger" @ok="handleDeleteRepository">
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
