<script>
import { GlLink, GlBadge, GlCard } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import defaultAvatarUrl from 'images/no_avatar.png';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CommitListItemActionButtons from './commit_list_item_action_buttons.vue';
import CommitListItemDescription from './commit_list_item_description.vue';

export default {
  name: 'CommitItem',
  components: {
    TimeagoTooltip,
    UserAvatarImage,
    UserAvatarLink,
    GlLink,
    CiIcon,
    SignatureBadge,
    GlBadge,
    GlCard,
    ActionButtons: CommitListItemActionButtons,
    Description: CommitListItemDescription,
  },
  directives: {
    SafeHtml,
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
  <li class="gl-mb-3 gl-ml-7">
    <gl-card
      :id="anchorId"
      :body-class="isCollapsed ? 'gl-hidden' : ''"
      :header-class="isCollapsed ? 'gl-border-b-0' : ''"
      class="gl-overflow-hidden gl-rounded-lg"
    >
      <template #header>
        <div class="gl-flex gl-w-full gl-items-center">
          <user-avatar-link
            v-if="commit.author"
            :link-href="commit.author.webPath"
            :img-src="commit.author.avatarUrl"
            :img-alt="avatarLinkAltText"
            :img-size="32"
            class="gl-my-2 gl-mr-5"
          />
          <user-avatar-image
            v-else
            class="gl-my-2 gl-mr-5"
            :img-src="commit.authorGravatar || $options.defaultAvatarUrl"
            :size="32"
          />
          <div class="gl-min-w-0 gl-grow">
            <gl-link
              v-safe-html:[$options.safeHtmlConfig]="commit.titleHtml"
              :href="commit.webPath"
              :class="{ 'gl-italic': !commit.message }"
              class="gl-line-clamp-1 gl-whitespace-normal !gl-break-all gl-text-lg gl-font-bold gl-text-default hover:gl-text-default"
              data-testid="commit-title-link"
            />
            <div class="gl-basis-full gl-truncate gl-text-subtle">
              <div
                v-if="commit.author"
                :data-user-id="userId"
                :data-username="commit.author.username"
                data-testid="commit-user-popover"
                class="js-user-popover gl-inline-block"
              >
                <gl-link
                  :href="commit.author.webPath"
                  class="js-user-link gl-text-default"
                  data-testid="commit-author-link"
                >
                  {{ commit.author.name }}</gl-link
                >
              </div>
              <template v-else>
                {{ commit.authorName }}
              </template>
              {{ __('authored') }}
              <timeago-tooltip :time="commit.authoredDate" tooltip-placement="bottom" />
            </div>
          </div>
          <div class="gl-flex gl-items-center gl-gap-4">
            <div class="gl-flex gl-items-center gl-gap-3">
              <gl-badge v-if="commit.tag" icon="tag" variant="muted" class="gl-h-6">{{
                commit.tag.name
              }}</gl-badge>
              <signature-badge
                v-if="commit.signature"
                :signature="commit.signature"
                class="!gl-ml-0 gl-h-6"
              />
              <div v-if="commit.pipelines.edges.length" class="gl-flex gl-items-center">
                <ci-icon :status="commit.pipelines.edges[0].node.detailedStatus" />
              </div>
            </div>
            <action-buttons
              :is-collapsed="isCollapsed"
              :commit="commit"
              :anchor-id="anchorId"
              @click="onClick"
            />
          </div>
        </div>
      </template>
      <template v-if="!isCollapsed" #default>
        <description :commit="commit" class="gl-display gl-block" />
      </template>
    </gl-card>
  </li>
</template>
!
