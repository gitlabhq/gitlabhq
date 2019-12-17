<script>
import { __ } from '~/locale';
import {
  GlAvatar,
  GlIcon,
  GlSprintf,
  GlButton,
  GlModal,
  GlAlert,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
} from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import DeleteSnippetMutation from '../mutations/deleteSnippet.mutation.graphql';
import CanCreatePersonalSnippet from '../queries/userPermissions.query.graphql';
import CanCreateProjectSnippet from '../queries/projectPermissions.query.graphql';

export default {
  components: {
    GlAvatar,
    GlIcon,
    GlSprintf,
    GlButton,
    GlModal,
    GlAlert,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    TimeAgoTooltip,
  },
  apollo: {
    canCreateSnippet: {
      query() {
        return this.snippet.project ? CanCreateProjectSnippet : CanCreatePersonalSnippet;
      },
      variables() {
        return {
          fullPath: this.snippet.project ? this.snippet.project.fullPath : undefined,
        };
      },
      update(data) {
        return this.snippet.project
          ? data.project.userPermissions.createSnippet
          : data.currentUser.userPermissions.createSnippet;
      },
    },
  },
  props: {
    snippet: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDeleting: false,
      errorMessage: '',
      canCreateSnippet: false,
    };
  },
  computed: {
    personalSnippetActions() {
      return [
        {
          condition: this.snippet.userPermissions.updateSnippet,
          text: __('Edit'),
          href: this.editLink,
          click: undefined,
          variant: 'outline-info',
          cssClass: undefined,
        },
        {
          condition: this.snippet.userPermissions.adminSnippet,
          text: __('Delete'),
          href: undefined,
          click: this.showDeleteModal,
          variant: 'outline-danger',
          cssClass: 'btn-inverted btn-danger ml-2',
        },
        {
          condition: this.canCreateSnippet,
          text: __('New snippet'),
          href: this.snippet.project
            ? `${this.snippet.project.webUrl}/snippets/new`
            : '/snippets/new',
          click: undefined,
          variant: 'outline-success',
          cssClass: 'btn-inverted btn-success ml-2',
        },
      ];
    },
    editLink() {
      return `${this.snippet.webUrl}/edit`;
    },
    visibility() {
      return this.snippet.visibilityLevel;
    },
    snippetVisibilityLevelDescription() {
      switch (this.visibility) {
        case 'private':
          return this.snippet.project !== null
            ? __('The snippet is visible only to project members.')
            : __('The snippet is visible only to me.');
        case 'internal':
          return __('The snippet is visible to any logged in user.');
        default:
          return __('The snippet can be accessed without any authentication.');
      }
    },
    visibilityLevelIcon() {
      switch (this.visibility) {
        case 'private':
          return 'lock';
        case 'internal':
          return 'shield';
        default:
          return 'earth';
      }
    },
  },
  methods: {
    redirectToSnippets() {
      window.location.pathname = 'dashboard/snippets';
    },
    closeDeleteModal() {
      this.$refs.deleteModal.hide();
    },
    showDeleteModal() {
      this.$refs.deleteModal.show();
    },
    deleteSnippet() {
      this.isDeleting = true;
      this.$apollo
        .mutate({
          mutation: DeleteSnippetMutation,
          variables: { id: this.snippet.id },
        })
        .then(() => {
          this.isDeleting = false;
          this.errorMessage = undefined;
          this.closeDeleteModal();
          this.redirectToSnippets();
        })
        .catch(err => {
          this.isDeleting = false;
          this.errorMessage = err.message;
        });
    },
  },
};
</script>
<template>
  <div class="detail-page-header">
    <div class="detail-page-header-body">
      <div
        class="snippet-box qa-snippet-box has-tooltip d-flex align-items-center append-right-5 mb-1"
        :title="snippetVisibilityLevelDescription"
        data-container="body"
      >
        <span class="sr-only">
          {{ s__(`VisibilityLevel|${visibility}`) }}
        </span>
        <gl-icon :name="visibilityLevelIcon" :size="14" />
      </div>
      <div class="creator">
        <gl-sprintf message="Authored %{timeago} by %{author}">
          <template #timeago>
            <time-ago-tooltip
              :time="snippet.createdAt"
              tooltip-placement="bottom"
              css-class="snippet_updated_ago"
            />
          </template>
          <template #author>
            <a :href="snippet.author.webUrl" class="d-inline">
              <gl-avatar :size="24" :src="snippet.author.avatarUrl" />
              <span class="bold">{{ snippet.author.name }}</span>
            </a>
          </template>
        </gl-sprintf>
      </div>
    </div>

    <div class="detail-page-header-actions">
      <div class="d-none d-sm-block">
        <template v-for="(action, index) in personalSnippetActions">
          <gl-button
            v-if="action.condition"
            :key="index"
            :variant="action.variant"
            :class="action.cssClass"
            :href="action.href || undefined"
            @click="action.click ? action.click() : undefined"
          >
            {{ action.text }}
          </gl-button>
        </template>
      </div>
      <div class="d-block d-sm-none dropdown">
        <gl-dropdown :text="__('Options')" class="w-100" toggle-class="text-center">
          <gl-dropdown-item
            v-for="(action, index) in personalSnippetActions"
            :key="index"
            :href="action.href || undefined"
            @click="action.click ? action.click() : undefined"
            >{{ action.text }}</gl-dropdown-item
          >
        </gl-dropdown>
      </div>
    </div>

    <gl-modal ref="deleteModal" modal-id="delete-modal" title="Example title">
      <template #modal-title>{{ __('Delete snippet?') }}</template>

      <gl-alert v-if="errorMessage" variant="danger" class="mb-2" @dismiss="errorMessage = ''">{{
        errorMessage
      }}</gl-alert>

      <gl-sprintf message="Are you sure you want to delete %{name}?">
        <template #name
          ><strong>{{ snippet.title }}</strong></template
        >
      </gl-sprintf>

      <template #modal-footer>
        <gl-button @click="closeDeleteModal">{{ __('Cancel') }}</gl-button>
        <gl-button
          variant="danger"
          :disabled="isDeleting"
          data-qa-selector="delete_snippet_button"
          @click="deleteSnippet"
        >
          <gl-loading-icon v-if="isDeleting" inline />
          {{ __('Delete snippet') }}
        </gl-button>
      </template>
    </gl-modal>
  </div>
</template>
