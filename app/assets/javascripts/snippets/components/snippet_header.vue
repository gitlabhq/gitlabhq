<script>
import {
  GlAvatar,
  GlIcon,
  GlSprintf,
  GlModal,
  GlAlert,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import CanCreateProjectSnippet from 'shared_queries/snippet/project_permissions.query.graphql';
import CanCreatePersonalSnippet from 'shared_queries/snippet/user_permissions.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createAlert, VARIANT_DANGER, VARIANT_SUCCESS } from '~/alert';

import DeleteSnippetMutation from '../mutations/delete_snippet.mutation.graphql';

export const i18n = {
  snippetSpamSuccess: sprintf(
    s__('Snippets|%{spammable_titlecase} was submitted to Akismet successfully.'),
    { spammable_titlecase: __('Snippet') },
  ),
  snippetSpamFailure: s__('Snippets|Error with Akismet. Please check the logs for more info.'),
};

export default {
  components: {
    GlAvatar,
    GlIcon,
    GlSprintf,
    GlModal,
    GlAlert,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    TimeAgoTooltip,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  apollo: {
    canCreateSnippet: {
      fetchPolicy: fetchPolicies.NO_CACHE,
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
          : data.currentUser?.userPermissions.createSnippet;
      },
    },
  },
  inject: ['reportAbusePath', 'canReportSpam'],
  props: {
    snippet: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      isSubmittingSpam: false,
      errorMessage: '',
      canCreateSnippet: false,
      isDeleteModalVisible: false,
    };
  },
  computed: {
    snippetHasBinary() {
      return Boolean(this.snippet.blobs.find((blob) => blob.binary));
    },
    authoredMessage() {
      return this.snippet.author
        ? __('Authored %{timeago} by %{author}')
        : __('Authored %{timeago}');
    },
    personalSnippetActions() {
      return [
        {
          condition: this.snippet.userPermissions.updateSnippet,
          text: __('Edit'),
          href: this.editLink,
          disabled: this.snippetHasBinary,
          title: this.snippetHasBinary
            ? __('Snippets with non-text files can only be edited via Git.')
            : undefined,
        },
        {
          condition: this.snippet.userPermissions.adminSnippet,
          text: __('Delete'),
          click: this.showDeleteModal,
          variant: 'danger',
          category: 'secondary',
        },
        {
          condition: this.canCreateSnippet,
          text: __('New snippet'),
          href: this.snippet.project
            ? joinPaths(this.snippet.project.webUrl, '-/snippets/new')
            : joinPaths('/', gon.relative_url_root, '/-/snippets/new'),
          variant: 'confirm',
          category: 'secondary',
        },
        {
          condition: this.canReportSpam && !isEmpty(this.reportAbusePath),
          text: __('Submit as spam'),
          click: this.submitAsSpam,
          title: __('Submit as spam'),
          loading: this.isSubmittingSpam,
        },
      ];
    },
    hasPersonalSnippetActions() {
      return Boolean(this.personalSnippetActions.filter(({ condition }) => condition).length);
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
          return __('The snippet is visible to any logged in user except external users.');
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
      window.location.pathname = this.snippet.project
        ? `${this.snippet.project.fullPath}/-/snippets`
        : `${gon.relative_url_root}dashboard/snippets`;
    },
    closeDeleteModal() {
      this.isDeleteModalVisible = false;
    },
    showDeleteModal() {
      this.isDeleteModalVisible = true;
    },
    deleteSnippet() {
      this.isLoading = true;
      this.$apollo
        .mutate({
          mutation: DeleteSnippetMutation,
          variables: { id: this.snippet.id },
        })
        .then(({ data }) => {
          if (data?.destroySnippet?.errors.length) {
            throw new Error(data?.destroySnippet?.errors[0]);
          }
          this.errorMessage = undefined;
          this.closeDeleteModal();
          this.redirectToSnippets();
        })
        .catch((err) => {
          this.isLoading = false;
          this.errorMessage = err.message;
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    async submitAsSpam() {
      try {
        this.isSubmittingSpam = true;
        await axios.post(this.reportAbusePath);
        createAlert({
          message: this.$options.i18n.snippetSpamSuccess,
          variant: VARIANT_SUCCESS,
        });
      } catch (error) {
        createAlert({ message: this.$options.i18n.snippetSpamFailure, variant: VARIANT_DANGER });
      } finally {
        this.isSubmittingSpam = false;
      }
    },
  },
  i18n,
};
</script>
<template>
  <div class="detail-page-header">
    <div class="detail-page-header-body">
      <div
        class="snippet-box has-tooltip d-flex align-items-center gl-mr-2 mb-1"
        data-qa-selector="snippet_container"
        :title="snippetVisibilityLevelDescription"
        data-container="body"
      >
        <span class="sr-only">{{ s__(`VisibilityLevel|${visibility}`) }}</span>
        <gl-icon :name="visibilityLevelIcon" :size="14" />
      </div>
      <div class="creator" data-testid="authored-message">
        <gl-sprintf :message="authoredMessage">
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
            <gl-emoji
              v-if="snippet.author.status"
              v-gl-tooltip
              class="gl-vertical-align-baseline font-size-inherit gl-mr-1"
              :title="snippet.author.status.message"
              :data-name="snippet.author.status.emoji"
            />
          </template>
        </gl-sprintf>
      </div>
    </div>

    <div v-if="hasPersonalSnippetActions" class="detail-page-header-actions">
      <div class="d-none d-sm-flex">
        <template v-for="(action, index) in personalSnippetActions">
          <div
            v-if="action.condition"
            :key="index"
            v-gl-tooltip
            :title="action.title"
            class="d-inline-block"
            :class="{ 'gl-ml-3': index > 0 }"
          >
            <gl-button
              :disabled="action.disabled"
              :loading="action.loading"
              :variant="action.variant"
              :category="action.category"
              :class="action.cssClass"
              :href="action.href"
              data-qa-selector="snippet_action_button"
              :data-qa-action="action.text"
              @click="action.click ? action.click() : undefined"
              >{{ action.text }}</gl-button
            >
          </div>
        </template>
      </div>
      <div class="d-block d-sm-none dropdown">
        <gl-dropdown :text="__('Options')" block>
          <template v-for="(action, index) in personalSnippetActions">
            <gl-dropdown-item
              v-if="action.condition"
              :key="index"
              :disabled="action.disabled"
              :title="action.title"
              :href="action.href"
              @click="action.click ? action.click() : undefined"
              >{{ action.text }}</gl-dropdown-item
            >
          </template>
        </gl-dropdown>
      </div>
    </div>

    <gl-modal
      ref="deleteModal"
      v-model="isDeleteModalVisible"
      modal-id="delete-modal"
      title="Example title"
    >
      <template #modal-title>{{ __('Delete snippet?') }}</template>

      <gl-alert
        v-if="errorMessage"
        variant="danger"
        class="mb-2"
        data-testid="delete-alert"
        @dismiss="errorMessage = ''"
        >{{ errorMessage }}</gl-alert
      >

      <gl-sprintf :message="__('Are you sure you want to delete %{name}?')">
        <template #name>
          <strong>{{ snippet.title }}</strong>
        </template>
      </gl-sprintf>

      <template #modal-footer>
        <gl-button @click="closeDeleteModal">{{ __('Cancel') }}</gl-button>
        <gl-button
          variant="danger"
          category="primary"
          :disabled="isLoading"
          data-qa-selector="delete_snippet_button"
          data-testid="delete-snippet"
          @click="deleteSnippet"
        >
          <gl-loading-icon v-if="isLoading" size="sm" inline />
          {{ __('Delete snippet') }}
        </gl-button>
      </template>
    </gl-modal>
  </div>
</template>
