<script>
import { GlLink, GlCollapse, GlTooltipDirective } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { __, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import defaultAvatarUrl from 'images/no_avatar.png';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { isValidDate, newDate } from '~/lib/utils/datetime_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import ExpandCollapseButton from '~/vue_shared/components/expand_collapse_button/expand_collapse_button.vue';
import CommitListItemActionButtons from './commit_list_item_action_buttons.vue';
import CommitListItemDescription from './commit_list_item_description.vue';
import CommitListItemOverflowMenu from './commit_list_item_overflow_menu.vue';
import CommitListItemBadges from './commit_list_item_badges.vue';

export default {
  name: 'CommitItem',
  components: {
    ExpandCollapseButton,
    TimeagoTooltip,
    UserAvatarImage,
    UserAvatarLink,
    GlLink,
    GlCollapse,
    ActionButtons: CommitListItemActionButtons,
    Description: CommitListItemDescription,
    OverflowMenu: CommitListItemOverflowMenu,
    Badges: CommitListItemBadges,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isCollapsed: true,
      // Latched on the first expand and kept mounted afterwards, so the
      // collapse animates over real content and re-expands don't re-fetch.
      hasExpanded: false,
      // Gate the open animation on this so the collapse expands straight to the
      // loaded content's height instead of jumping when it resolves.
      descriptionReady: false,
    };
  },
  computed: {
    avatarLinkAltText() {
      return sprintf(__(`%{username}'s avatar`), { username: this.commit.authorName });
    },
    userId() {
      return this.commit.author ? getIdFromGraphQLId(this.commit.author.id) : null;
    },
    anchorId() {
      return `commit-list-item-${this.commit.id}`;
    },
    hasParsableAuthoredDate() {
      return isValidDate(newDate(this.commit.authoredDate));
    },
    isExpanded() {
      return !this.isCollapsed && this.descriptionReady;
    },
    isLoadingDescription() {
      return !this.isCollapsed && !this.descriptionReady;
    },
  },
  destroyed() {
    this.isCollapsed = true;
  },
  defaultAvatarUrl,
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
  methods: {
    onClick() {
      this.isCollapsed = !this.isCollapsed;
      if (!this.isCollapsed) {
        this.hasExpanded = true;
      }
      this.trackEvent('expand_collapse_commit_list_item', {
        label: this.isCollapsed ? 'collapse' : 'expand',
      });
    },
    onDescriptionLoaded() {
      this.descriptionReady = true;
    },
    onRowClick(event) {
      // Ignore clicks originating from interactive controls (links, buttons).
      // We can't use `@click.stop` on their wrapper because clipboard.js relies
      // on the click event bubbling up to its delegated listener on `document`.
      if (event.target.closest('a, button')) return;
      if (!this.commit.description) return;
      this.onClick();
    },
  },
};
</script>

<template>
  <li
    class="commit-list-item commit-card gl-border gl-overflow-hidden gl-rounded-lg @md/panel:gl-ml-7"
  >
    <div
      class="gl-flex gl-w-full gl-items-center gl-px-4 gl-py-3 focus:-gl-outline-offset-2"
      :class="{ 'gl-cursor-pointer': commit.description }"
      :tabindex="commit.description ? 0 : -1"
      :aria-expanded="commit.description ? String(!isCollapsed) : undefined"
      data-testid="commit-row"
      @click="onRowClick"
      @keydown.enter="onRowClick"
      @keydown.space.prevent="onRowClick"
    >
      <!-- Prevent the description toggle -->
      <user-avatar-link
        v-if="commit.author"
        lazy
        :link-href="commit.author.webPath"
        :img-src="commit.author.avatarUrl"
        :img-alt="avatarLinkAltText"
        :img-size="32"
        class="gl-my-2 gl-mr-5 gl-hidden @md/panel:gl-block"
        @click.stop
      />
      <user-avatar-image
        v-else
        lazy
        class="gl-my-2 gl-mr-5 gl-hidden @md/panel:gl-block"
        :img-src="commit.authorGravatar || $options.defaultAvatarUrl"
        :size="32"
      />
      <div class="gl-inline-block gl-w-full gl-min-w-0 gl-items-center @md/panel:gl-flex">
        <h3 class="gl-m-0 gl-min-w-0 gl-grow gl-pt-1 gl-text-base @md/panel:gl-pt-0">
          <div class="gl-flex">
            <!-- Prevent the description toggle -->
            <gl-link
              :href="commit.webPath"
              class="gl-inline-block gl-min-w-0 gl-max-w-full gl-font-bold gl-text-default hover:gl-text-default @md/panel:gl-truncate"
              data-testid="commit-title-link"
              :title="commit.title"
              @click.stop
            >
              {{ commit.title }}
            </gl-link>
          </div>
          <div
            class="gl-text-wrap gl-pb-2 gl-pt-1 gl-text-sm gl-font-normal !gl-text-subtle @md/panel:gl-pb-0 @md/panel:gl-pt-0"
          >
            <span
              v-if="commit.author"
              :data-user-id="userId"
              :data-username="commit.author.username"
              data-testid="commit-user-popover"
              class="js-user-popover"
            >
              <!-- Prevent the description toggle -->
              <gl-link
                :href="commit.author.webPath"
                class="js-user-link gl-text-default"
                data-testid="commit-author-link"
                @click.stop
              >
                {{ commit.author.name }}</gl-link
              >
            </span>
            <span v-else>
              {{ commit.authorName }}
            </span>
            {{ __('authored') }}
            <timeago-tooltip
              v-if="hasParsableAuthoredDate"
              :time="commit.authoredDate"
              tooltip-placement="bottom"
            />
            <span v-else data-testid="commit-authored-date-fallback">{{
              commit.authoredDate
            }}</span>
          </div>
        </h3>
        <div class="gl-flex gl-items-center gl-gap-4">
          <badges :commit="commit" />
          <action-buttons
            :is-collapsed="isCollapsed"
            :is-loading="isLoadingDescription"
            :commit="commit"
            :anchor-id="anchorId"
            @click="onClick"
          />
        </div>
      </div>
      <!-- Prevent the description toggle -->
      <div
        v-if="commit.description"
        class="gl-block @md/panel:gl-hidden"
        data-testid="narrow-screen-expand-collapse-button-container"
        @click.stop
      >
        <expand-collapse-button
          :is-collapsed="isCollapsed"
          :loading="isLoadingDescription"
          :anchor-id="anchorId"
          :accessible-label="commit.titleHtml"
          size="medium"
          @click="onClick"
        />
      </div>
      <overflow-menu
        :commit="commit"
        class="gl-block @md/panel:gl-hidden"
        data-testid="overflow-menu"
      />
    </div>

    <gl-collapse :visible="isExpanded">
      <div class="gl-border-t gl-bg-subtle gl-px-4 gl-py-3">
        <description
          v-if="hasExpanded"
          :id="anchorId"
          :commit-sha="commit.sha"
          class="gl-display gl-block"
          @loaded="onDescriptionLoaded"
        />
      </div>
    </gl-collapse>
  </li>
</template>
