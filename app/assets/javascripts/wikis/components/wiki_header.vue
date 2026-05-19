<script>
import {
  GlButton,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
  GlIcon,
  GlModalDirective,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import wikiPageSubscribeMutation from '~/wikis/graphql/wiki_page_subscribe.mutation.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WikiSidebarToggle from '~/wikis/components/wiki_sidebar_toggle.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WikiMoreDropdown from './wiki_more_dropdown.vue';
import RestoreVersionModal from './restore_version_modal.vue';
import WikiStickyHeader from './wiki_sticky_header.vue';

export default {
  components: {
    WikiSidebarToggle,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    GlIntersectionObserver,
    WikiMoreDropdown,
    TimeAgo,
    PageHeading,
    RestoreVersionModal,
    WikiStickyHeader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    pageHeading: { default: null },
    showEditButton: { default: null },
    showRestoreVersionButton: { default: null },
    isPageTemplate: { default: null },
    editButtonUrl: { default: null },
    lastVersion: { default: null },
    pageVersion: { default: null },
    authorUrl: { default: null },
    isEditingPath: { default: null },
    wikiUrl: { default: null },
    createFromTemplateUrl: { default: null },
    pagePersisted: { default: null },
    queryVariables: { default: null },
  },
  apollo: {
    wikiPage: {
      query: wikiPageQuery,
      variables() {
        return { ...this.queryVariables, skipDiscussions: true };
      },
    },
  },
  data() {
    return {
      changingSubState: false,
      wikiPage: {},
      isStickyHeaderShowing: false,
    };
  },
  computed: {
    showCreateFromTemplateButton() {
      return this.showEditButton && this.isPageTemplate && this.createFromTemplateUrl;
    },
    pageHeadingComputed() {
      let { pageHeading } = this;

      if (this.isEditingPath) {
        if (this.wikiUrl.endsWith('_sidebar')) {
          pageHeading = this.pagePersisted
            ? this.$options.i18n.editSidebar
            : this.$options.i18n.newSidebar;
        } else if (this.isPageTemplate) {
          pageHeading = this.pagePersisted
            ? this.$options.i18n.editTemplate
            : this.$options.i18n.newTemplate;
        } else {
          pageHeading = this.pagePersisted
            ? this.$options.i18n.editPage
            : this.$options.i18n.newPage;
        }
      }

      return pageHeading;
    },
    editTooltipText() {
      return this.isPageTemplate ? this.$options.i18n.editTemplate : this.$options.i18n.editPage;
    },
    editTooltip() {
      return `${this.editTooltipText} <kbd class='flat gl-ml-2' aria-hidden=true>e</kbd>`;
    },
    subscribeItem() {
      return {
        text: this.wikiPage?.subscribed ? __('Notifications On') : __('Notifications Off'),
        icon: this.wikiPage?.subscribed ? 'notifications' : 'notifications-off',
      };
    },
    isStickyHeaderVisible() {
      // hide sticky when in editing path, title changes and Edit button is irrelevant , also hide when restore version button is shown as it appears in the same place and Edit button is hidden
      return this.isStickyHeaderShowing && !this.isEditingPath && !this.showRestoreVersionButton;
    },
  },
  mounted() {
    if (this.showEditButton) {
      document.addEventListener('keyup', this.onKeyUp);
    }
  },
  destroyed() {
    if (this.showEditButton) {
      document.removeEventListener('keyup', this.onKeyUp);
    }
  },
  methods: {
    hideStickyHeader() {
      this.isStickyHeaderShowing = false;
    },
    showStickyHeader() {
      this.isStickyHeaderShowing = true;
    },
    onKeyUp(event) {
      const { tagName, isContentEditable } = event.currentTarget.activeElement;

      if (/input|textarea/i.test(tagName) || isContentEditable) return false;

      if (event.key === 'e') {
        this.setEditingMode();
      }

      return false;
    },
    setEditingMode() {
      this.$emit('is-editing', true);
    },
    async toggleSubscribe() {
      if (this.changingSubState) return;

      this.changingSubState = true;
      const newSubState = !this.wikiPage.subscribed;

      try {
        await this.$apollo.mutate({
          mutation: wikiPageSubscribeMutation,
          variables: {
            id: this.wikiPage.id,
            subscribed: newSubState,
          },
          optimisticResponse: {
            wikiPageSubscribe: {
              errors: [],
              wikiPage: {
                id: this.wikiPage.id,
                subscribed: newSubState,
              },
            },
          },
        });

        const message = newSubState
          ? __('Notifications turned on')
          : __('Notifications turned off');
        this.$toast.show(message);
      } catch (error) {
        this.handleSubscribeError(error, newSubState);
      }

      this.changingSubState = false;
    },
    handleSubscribeError(error, newSubState) {
      const message = newSubState
        ? __('An error occurred while subscribing to this page. Please try again later.')
        : __('An error occurred while unsubscribing from this page. Please try again later.');

      this.$toast.show(message);
      Sentry.captureException(error);
    },
  },
  i18n: {
    edit: __('Edit'),
    restoreText: __('Restore this version'),
    cancelText: __('Cancel'),
    newPage: s__('Wiki|New page'),
    editPage: s__('Wiki|Edit page'),
    newTemplate: s__('Wiki|New template'),
    editTemplate: s__('Wiki|Edit template'),
    newSidebar: s__('Wiki|New custom sidebar'),
    editSidebar: s__('Wiki|Edit custom sidebar'),
    lastEdited: s__('Wiki|Last edited by %{author} %{timeago}'),
    createFromTemplate: s__('Wiki|Create from template'),
    createFromTemplateTitle: s__('Wiki|Create a new wiki page using this template'),
  },
  modal: {
    restoreVersionModalId: 'wiki-restore-version-modal',
  },
};
</script>

<template>
  <div>
    <div id="top"></div>
    <gl-intersection-observer @appear="hideStickyHeader" @disappear="showStickyHeader">
      <div
        class="js-wiki-page-header wiki-page-header has-sidebar-toggle detail-page-header gl-flex gl-flex-wrap gl-border-b-0 gl-px-3 !gl-pt-0"
      >
        <page-heading class="gl-wrap-break-word gl-w-full">
          <template #heading>
            <span class="gl-flex gl-items-center">
              <div class="toggle-with-hide-transition -gl-mr-2 gl-mb-1">
                <wiki-sidebar-toggle action="open" />
              </div>
              <span>{{ pageHeadingComputed }}</span>
            </span>
          </template>

          <template v-if="!isEditingPath" #actions>
            <gl-button
              v-if="showCreateFromTemplateButton"
              v-gl-tooltip.html
              :title="$options.i18n.createFromTemplateTitle"
              data-testid="wiki-create-from-template-button"
              :href="createFromTemplateUrl"
            >
              {{ $options.i18n.createFromTemplate }}
            </gl-button>

            <gl-button
              v-if="showRestoreVersionButton"
              v-gl-modal="$options.modal.restoreVersionModalId"
              data-testid="wiki-restore-version-button"
            >
              {{ $options.i18n.restoreText }}
            </gl-button>

            <restore-version-modal :modal-id="$options.modal.restoreVersionModalId" />

            <gl-button
              v-if="showEditButton"
              v-gl-tooltip.html
              :title="editTooltip"
              data-testid="wiki-edit-button"
              @click="setEditingMode"
            >
              {{ $options.i18n.edit }}
            </gl-button>

            <gl-button
              v-gl-tooltip.html
              class="btn-icon"
              :disabled="!wikiPage.id"
              :title="subscribeItem.text"
              data-testid="wiki-subscribe-button"
              @click="toggleSubscribe"
            >
              <gl-icon
                :name="subscribeItem.icon"
                :class="{ '!gl-text-status-info': wikiPage.subscribed }"
              />
            </gl-button>

            <wiki-more-dropdown />
          </template>

          <template v-if="lastVersion" #description>
            <div class="wiki-last-version gl-leading-20" data-testid="wiki-page-last-version">
              <gl-sprintf :message="$options.i18n.lastEdited">
                <template #author>
                  <gl-link :href="authorUrl" class="gl-font-bold gl-text-default">{{
                    pageVersion.author_name
                  }}</gl-link>
                </template>
                <template #timeago>
                  <time-ago :time="pageVersion.authored_date" target="wiki-last-version" />
                </template>
              </gl-sprintf>
            </div>
          </template>
        </page-heading>
      </div>
    </gl-intersection-observer>

    <wiki-sticky-header
      :is-sticky-header-showing="isStickyHeaderVisible"
      :page-heading="pageHeadingComputed"
      :show-edit-button="Boolean(showEditButton)"
      :wiki-page="wikiPage"
      @edit="setEditingMode"
      @toggle-subscribe="toggleSubscribe"
    />
  </div>
</template>
