<script>
import { GlLink, GlCard, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import defaultAvatarUrl from 'images/no_avatar.png';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
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
    GlCard,
    ActionButtons: CommitListItemActionButtons,
    Description: CommitListItemDescription,
    OverflowMenu: CommitListItemOverflowMenu,
    Badges: CommitListItemBadges,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isCollapsed: true,
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
    },
  },
};
</script>

<template>
  <li class="commit-list-item @md/panel:gl-ml-7">
    <gl-card
      :body-class="isCollapsed ? 'gl-hidden' : ''"
      :header-class="isCollapsed ? 'gl-border-b-0 gl-rounded-lg' : ' gl-rounded-t-lg'"
      class="commit-card"
    >
      <template #header>
        <div class="gl-flex gl-w-full @md/panel:gl-items-center">
          <user-avatar-link
            v-if="commit.author"
            :link-href="commit.author.webPath"
            :img-src="commit.author.avatarUrl"
            :img-alt="avatarLinkAltText"
            :img-size="32"
            class="gl-my-2 gl-mr-5 gl-hidden @md/panel:gl-block"
          />
          <user-avatar-image
            v-else
            class="gl-my-2 gl-mr-5 gl-hidden @md/panel:gl-block"
            :img-src="commit.authorGravatar || $options.defaultAvatarUrl"
            :size="32"
          />
          <div class="gl-inline-block gl-w-full gl-min-w-0 gl-items-center @md/panel:gl-flex">
            <h3 class="gl-m-0 gl-min-w-0 gl-grow gl-text-base">
              <div class="gl-flex">
                <gl-link
                  :href="commit.webPath"
                  class="gl-inline-block gl-min-w-0 gl-max-w-full gl-truncate gl-font-bold gl-text-default hover:gl-text-default"
                  data-testid="commit-title-link"
                  :class="{ 'gl-italic': !commit.message }"
                  :title="commit.title"
                >
                  {{ commit.title }}
                </gl-link>
              </div>
              <div class="gl-text-wrap gl-text-sm gl-font-normal !gl-text-subtle">
                <span
                  v-if="commit.author"
                  :data-user-id="userId"
                  :data-username="commit.author.username"
                  data-testid="commit-user-popover"
                  class="js-user-popover"
                >
                  <gl-link
                    :href="commit.author.webPath"
                    class="js-user-link gl-text-default"
                    data-testid="commit-author-link"
                  >
                    {{ commit.author.name }}</gl-link
                  >
                </span>
                <span v-else>
                  {{ commit.authorName }}
                </span>
                {{ __('authored') }}
                <timeago-tooltip :time="commit.authoredDate" tooltip-placement="bottom" />
              </div>
            </h3>
            <div class="gl-flex gl-items-center gl-gap-4">
              <badges :commit="commit" />
              <action-buttons
                :is-collapsed="isCollapsed"
                :commit="commit"
                :anchor-id="anchorId"
                @click="onClick"
              />
            </div>
          </div>
          <overflow-menu
            :commit="commit"
            class="gl-block @md/panel:gl-hidden"
            data-testid="overflow-menu"
          />
          <div
            v-if="commit.description"
            class="gl-border-l gl-ml-3 gl-block gl-h-7 gl-border-l-section @md/panel:gl-hidden"
            data-testid="narrow-screen-expand-collapse-button-container"
          >
            <expand-collapse-button
              :is-collapsed="isCollapsed"
              :anchor-id="anchorId"
              :accessible-label="commit.titleHtml"
              size="medium"
              @click="onClick"
            />
          </div>
        </div>
      </template>

      <template v-if="!isCollapsed" #default>
        <description :id="anchorId" :commit-sha="commit.sha" class="gl-display gl-block" />
      </template>
    </gl-card>
  </li>
</template>
