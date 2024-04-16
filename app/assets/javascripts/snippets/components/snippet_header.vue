<script>
import {
  GlIcon,
  GlSprintf,
  GlModal,
  GlAlert,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
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
import SnippetCodeDropdown from '~/vue_shared/components/code_dropdown/snippet_code_dropdown.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createAlert, VARIANT_DANGER, VARIANT_SUCCESS } from '~/alert';
import { VISIBILITY_LEVEL_PUBLIC_STRING } from '~/visibility_level/constants';
import DeleteSnippetMutation from '../mutations/delete_snippet.mutation.graphql';

export const i18n = {
  snippetSpamSuccess: sprintf(
    s__('Snippets|%{spammable_titlecase} was submitted to Akismet successfully.'),
    { spammable_titlecase: __('Snippet') },
  ),
  snippetSpamFailure: s__('Snippets|Error with Akismet. Please check the logs for more info.'),
  hiddenTooltip: s__('Snippets|This snippet is hidden because its author has been banned'),
  hiddenAriaLabel: __('Hidden'),
  snippetAction: s__('Snippets|Snippet actions'),
};

export default {
  components: {
    SnippetCodeDropdown,
    GlIcon,
    GlSprintf,
    GlModal,
    GlAlert,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
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
      isDropdownShown: false,
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
    editItem() {
      return {
        text: __('Edit'),
        href: this.editLink,
        disabled: this.snippetHasBinary,
        title: this.snippetHasBinary
          ? __('Snippets with non-text files can only be edited via Git.')
          : undefined,
        extraAttrs: {
          class: 'gl-sm-display-none!',
        },
      };
    },
    canReportSpaCheck() {
      return this.canReportSpam && !isEmpty(this.reportAbusePath);
    },
    spamItem() {
      return {
        text: __('Submit as spam'),
        action: () => this.submitAsSpam(),
      };
    },
    deleteItem() {
      return {
        text: __('Delete'),
        action: () => this.showDeleteModal(),
        extraAttrs: {
          class: 'gl-text-red-500!',
        },
      };
    },
    newSnippetItem() {
      return {
        text: __('New snippet'),
        href: this.snippet.project
          ? joinPaths(this.snippet.project.webUrl, '-/snippets/new')
          : joinPaths('/', gon.relative_url_root, '/-/snippets/new'),
      };
    },
    hasPersonalSnippetActions() {
      return (
        this.snippet.userPermissions.updateSnippet ||
        this.canCreateSnippet ||
        this.snippet.userPermissions.adminSnippet ||
        this.canReportSpaCheck ||
        this.embedDropdown ||
        this.canBeCloned
      );
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
    showDropdownTooltip() {
      return !this.isDropdownShown ? this.$options.i18n.snippetAction : '';
    },
    isInPrivateProject() {
      const projectVisibility = this.snippet?.project?.visibility;
      const isLimitedVisibilityProject = projectVisibility !== VISIBILITY_LEVEL_PUBLIC_STRING;
      return projectVisibility ? isLimitedVisibilityProject : false;
    },
    embeddable() {
      return this.visibility === VISIBILITY_LEVEL_PUBLIC_STRING && !this.isInPrivateProject;
    },
    canBeCloned() {
      return Boolean(this.snippet.sshUrlToRepo || this.snippet.httpUrlToRepo);
    },
    canBeClonedOrEmbedded() {
      return this.canBeCloned || this.embeddable;
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
    onShowDropdown() {
      this.isDropdownShown = true;
    },
    onHideDropdown() {
      this.isDropdownShown = false;
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
  <div>
    <div
      class="gl-display-flex gl-align-items-flex-start gl-flex-direction-column gl-sm-flex-direction-row gl-gap-3 gl-pt-3"
    >
      <span
        v-if="snippet.hidden"
        class="gl-bg-orange-50 gl-text-orange-600 gl-h-6 gl-w-6 gl-rounded-base gl-line-height-24 gl-text-center gl-mt-2"
      >
        <gl-icon
          v-gl-tooltip.bottom
          name="spam"
          :title="$options.i18n.hiddenTooltip"
          :aria-label="$options.i18n.hiddenAriaLabel"
        />
      </span>

      <h1
        class="gl-font-size-h-display gl-w-full gl-m-0! gl-flex-grow-1"
        data-testid="snippet-title-content"
      >
        {{ snippet.title }}
      </h1>

      <div
        v-if="hasPersonalSnippetActions"
        class="gl-display-flex gl-align-self-center gl-gap-3 gl-w-full gl-sm-w-auto gl-flex-direction-column gl-sm-flex-direction-row"
      >
        <gl-button
          v-if="snippet.userPermissions.updateSnippet"
          :href="editItem.href"
          :title="editItem.title"
          :disabled="editItem.disabled"
          class="gl-display-none gl-sm-display-inline-block"
          data-testid="snippet-action-button"
          :data-qa-action="editItem.text"
        >
          {{ editItem.text }}
        </gl-button>

        <snippet-code-dropdown
          v-if="canBeClonedOrEmbedded"
          :ssh-link="snippet.sshUrlToRepo"
          :http-link="snippet.httpUrlToRepo"
          :url="snippet.webUrl"
          :embeddable="embeddable"
          data-testid="code-button"
        />

        <gl-disclosure-dropdown
          data-testid="snippets-more-actions-dropdown"
          placement="right"
          block
          @shown="onShowDropdown"
          @hidden="onHideDropdown"
        >
          <template #toggle>
            <div class="gl-w-full gl-min-h-7">
              <gl-button
                class="gl-sm-display-none! gl-new-dropdown-toggle gl-w-full"
                button-text-classes="gl-display-flex gl-justify-content-space-between gl-w-full"
                category="secondary"
                tabindex="0"
              >
                <span>{{ $options.i18n.snippetAction }}</span>
                <gl-icon class="dropdown-chevron" name="chevron-down" />
              </gl-button>
              <gl-button
                v-gl-tooltip="showDropdownTooltip"
                class="gl-display-none gl-sm-display-flex! gl-new-dropdown-toggle gl-new-dropdown-icon-only gl-new-dropdown-toggle-no-caret"
                category="tertiary"
                icon="ellipsis_v"
                :aria-label="$options.i18n.snippetAction"
                tabindex="0"
                data-testid="snippets-more-actions-dropdown-toggle"
              />
            </div>
          </template>
          <gl-disclosure-dropdown-item
            v-if="snippet.userPermissions.updateSnippet"
            :item="editItem"
          />
          <gl-disclosure-dropdown-item v-if="canCreateSnippet" :item="newSnippetItem" />
          <gl-disclosure-dropdown-group bordered>
            <gl-disclosure-dropdown-item v-if="canReportSpaCheck" :item="spamItem" />
            <gl-disclosure-dropdown-item
              v-if="snippet.userPermissions.adminSnippet"
              :item="deleteItem"
            />
          </gl-disclosure-dropdown-group>
        </gl-disclosure-dropdown>
      </div>
    </div>

    <div
      class="detail-page-header gl-flex-direction-column gl-md-flex-direction-row gl-p-0 gl-mb-5"
    >
      <div class="gl-display-flex gl-align-items-baseline">
        <div
          class="has-tooltip gl-display-flex gl-align-self-baseline gl-mt-3 gl-mr-2"
          data-testid="snippet-container"
          :title="snippetVisibilityLevelDescription"
          data-container="body"
        >
          <span class="gl-sr-only">{{ snippetVisibilityLevelDescription }}</span>
          <gl-icon :name="visibilityLevelIcon" :size="14" class="gl-relative gl-top-1" />
        </div>
        <div data-testid="authored-message" class="gl-line-height-20">
          <gl-sprintf :message="authoredMessage">
            <template #timeago>
              <time-ago-tooltip
                :time="snippet.createdAt"
                tooltip-placement="bottom"
                css-class="snippet_updated_ago"
              />
            </template>
            <template #author>
              <a :href="snippet.author.webUrl" class="gl-font-weight-bold">
                {{ snippet.author.name }}
              </a>
            </template>
          </gl-sprintf>
        </div>
      </div>

      <gl-modal
        v-model="isDeleteModalVisible"
        modal-id="delete-modal"
        :title="__('Delete snippet modal')"
      >
        <template #modal-title>{{ __('Delete snippet?') }}</template>

        <gl-alert
          v-if="errorMessage"
          variant="danger"
          class="gl-mb-3"
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
            :loading="isLoading"
            data-testid="delete-snippet-button"
            @click="deleteSnippet"
          >
            {{ __('Delete snippet') }}
          </gl-button>
        </template>
      </gl-modal>
    </div>
  </div>
</template>
