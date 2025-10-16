<script>
import { GlButton, GlLink, GlSprintf, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import wikiPageSubscribeMutation from '~/wikis/graphql/wiki_page_subscribe.mutation.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WikiMoreDropdown from './wiki_more_dropdown.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    WikiMoreDropdown,
    TimeAgo,
    PageHeading,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    pageHeading: { default: null },
    showEditButton: { default: null },
    isPageTemplate: { default: null },
    editButtonUrl: { default: null },
    lastVersion: { default: null },
    pageVersion: { default: null },
    authorUrl: { default: null },
    isEditingPath: { default: null },
    wikiUrl: { default: null },
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
    };
  },
  computed: {
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
        action: this.toggleSubscribe,
        extraAttrs: {
          'data-testid': 'page-subscribe-button',
        },
      };
    },
  },
  mounted() {
    if (this.editButtonUrl) {
      document.addEventListener('keyup', this.onKeyUp);
    }
  },
  destroyed() {
    document.removeEventListener('keyup', this.onKeyUp);
  },
  methods: {
    onKeyUp(event) {
      const { tagName, isContentEditable } = event.currentTarget.activeElement;

      if (/input|textarea/i.test(tagName) || isContentEditable) return false;

      if (event.key === 'e') {
        this.$emit('is-editing', true);
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
    newPage: s__('Wiki|New page'),
    editPage: s__('Wiki|Edit page'),
    newTemplate: s__('Wiki|New template'),
    editTemplate: s__('Wiki|Edit template'),
    newSidebar: s__('Wiki|New custom sidebar'),
    editSidebar: s__('Wiki|Edit custom sidebar'),
    lastEdited: s__('Wiki|Last edited by %{author} %{timeago}'),
  },
};
</script>

<template>
  <div
    class="js-wiki-page-header wiki-page-header has-sidebar-toggle detail-page-header gl-flex gl-flex-wrap gl-border-b-0 !gl-pt-0"
  >
    <page-heading class="gl-w-full">
      <template #heading>
        <gl-button
          v-gl-tooltip.html
          data-testid="wiki-sidebar-toggle"
          icon="list-bulleted"
          category="tertiary"
          class="wiki-sidebar-header-toggle js-sidebar-wiki-toggle-open gl-mr-2"
          :aria-label="__('Toggle sidebar')"
        />
        <span>
          {{ pageHeadingComputed }}
        </span>
      </template>
      <template v-if="!isEditingPath" #actions>
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
</template>
