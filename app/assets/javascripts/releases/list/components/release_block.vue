<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import _ from 'underscore';
import { GlTooltipDirective, GlLink, GlBadge, GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { __, n__, sprintf } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import { getLocationHash } from '~/lib/utils/url_utility';
import { scrollToElement } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ReleaseBlockFooter from './release_block_footer.vue';
import EvidenceBlock from './evidence_block.vue';
import ReleaseBlockMilestoneInfo from './release_block_milestone_info.vue';

export default {
  name: 'ReleaseBlock',
  components: {
    EvidenceBlock,
    GlLink,
    GlBadge,
    GlButton,
    Icon,
    UserAvatarLink,
    ReleaseBlockFooter,
    ReleaseBlockMilestoneInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin, glFeatureFlagsMixin()],
  props: {
    release: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  data() {
    return {
      isHighlighted: false,
    };
  },
  computed: {
    id() {
      return slugify(this.release.tag_name);
    },
    releasedTimeAgo() {
      return sprintf(__('released %{time}'), {
        time: this.timeFormatted(this.release.released_at),
      });
    },
    userImageAltDescription() {
      return this.author && this.author.username
        ? sprintf(__("%{username}'s avatar"), { username: this.author.username })
        : null;
    },
    commit() {
      return this.release.commit || {};
    },
    commitUrl() {
      return this.release.commit_path;
    },
    tagUrl() {
      return this.release.tag_path;
    },
    assets() {
      return this.release.assets || {};
    },
    author() {
      return this.release.author || {};
    },
    hasAuthor() {
      return !_.isEmpty(this.author);
    },
    hasEvidence() {
      return Boolean(this.release.evidence_sha);
    },
    shouldRenderMilestones() {
      return !_.isEmpty(this.release.milestones);
    },
    labelText() {
      return n__('Milestone', 'Milestones', this.release.milestones.length);
    },
    shouldShowEditButton() {
      return Boolean(this.release._links && this.release._links.edit_url);
    },
    shouldShowEvidence() {
      return this.glFeatures.releaseEvidenceCollection;
    },
    shouldShowFooter() {
      return this.glFeatures.releaseIssueSummary;
    },
    shouldRenderReleaseMetaData() {
      return !this.glFeatures.releaseIssueSummary;
    },
    shouldRenderMilestoneInfo() {
      return Boolean(this.glFeatures.releaseIssueSummary && !_.isEmpty(this.release.milestones));
    },
  },
  mounted() {
    const hash = getLocationHash();
    if (hash && slugify(hash) === this.id) {
      this.isHighlighted = true;
      setTimeout(() => {
        this.isHighlighted = false;
      }, 2000);

      scrollToElement(this.$el);
    }
  },
};
</script>
<template>
  <div :id="id" :class="{ 'bg-line-target-blue': isHighlighted }" class="card release-block">
    <div class="card-header d-flex align-items-center bg-white pr-0">
      <h2 class="card-title my-2 mr-auto gl-font-size-20">
        {{ release.name }}
        <gl-badge v-if="release.upcoming_release" variant="warning" class="align-middle">{{
          __('Upcoming Release')
        }}</gl-badge>
      </h2>
      <gl-link
        v-if="shouldShowEditButton"
        v-gl-tooltip
        class="btn btn-default append-right-10 js-edit-button ml-2"
        :title="__('Edit this release')"
        :href="release._links.edit_url"
      >
        <icon name="pencil" />
      </gl-link>
    </div>
    <div class="card-body">
      <div v-if="shouldRenderMilestoneInfo">
        <release-block-milestone-info :milestones="release.milestones" />
        <hr class="mb-3 mt-0" />
      </div>

      <div v-if="shouldRenderReleaseMetaData" class="card-subtitle d-flex flex-wrap text-secondary">
        <div class="append-right-8">
          <icon name="commit" class="align-middle" />
          <gl-link v-if="commitUrl" v-gl-tooltip.bottom :title="commit.title" :href="commitUrl">
            {{ commit.short_id }}
          </gl-link>
          <span v-else v-gl-tooltip.bottom :title="commit.title">{{ commit.short_id }}</span>
        </div>

        <div class="append-right-8">
          <icon name="tag" class="align-middle" />
          <gl-link v-if="tagUrl" v-gl-tooltip.bottom :title="__('Tag')" :href="tagUrl">
            {{ release.tag_name }}
          </gl-link>
          <span v-else v-gl-tooltip.bottom :title="__('Tag')">{{ release.tag_name }}</span>
        </div>

        <template v-if="shouldRenderMilestones">
          <div class="js-milestone-list-label">
            <icon name="flag" class="align-middle" />
            <span class="js-label-text">{{ labelText }}</span>
          </div>

          <template v-for="(milestone, index) in release.milestones">
            <gl-link
              :key="milestone.id"
              v-gl-tooltip
              :title="milestone.description"
              :href="milestone.web_url"
              class="append-right-4 prepend-left-4 js-milestone-link"
            >
              {{ milestone.title }}
            </gl-link>
            <template v-if="index !== release.milestones.length - 1">
              &bull;
            </template>
          </template>
        </template>

        <div class="append-right-4">
          &bull;
          <span v-gl-tooltip.bottom :title="tooltipTitle(release.released_at)">
            {{ releasedTimeAgo }}
          </span>
        </div>

        <div v-if="hasAuthor" class="d-flex">
          by
          <user-avatar-link
            class="prepend-left-4"
            :link-href="author.web_url"
            :img-src="author.avatar_url"
            :img-alt="userImageAltDescription"
            :tooltip-text="author.username"
          />
        </div>
      </div>

      <div
        v-if="assets.links.length || (assets.sources && assets.sources.length)"
        class="card-text prepend-top-default"
      >
        <b>
          {{ __('Assets') }}
          <span class="js-assets-count badge badge-pill">{{ assets.count }}</span>
        </b>

        <ul v-if="assets.links.length" class="pl-0 mb-0 prepend-top-8 list-unstyled js-assets-list">
          <li v-for="link in assets.links" :key="link.name" class="append-bottom-8">
            <gl-link v-gl-tooltip.bottom :title="__('Download asset')" :href="link.url">
              <icon name="package" class="align-middle append-right-4 align-text-bottom" />
              {{ link.name }}
              <span v-if="link.external">{{ __('(external source)') }}</span>
            </gl-link>
          </li>
        </ul>

        <div v-if="assets.sources && assets.sources.length" class="dropdown">
          <button
            type="button"
            class="btn btn-link"
            data-toggle="dropdown"
            aria-haspopup="true"
            aria-expanded="false"
          >
            <icon name="doc-code" class="align-top append-right-4" />
            {{ __('Source code') }}
            <icon name="arrow-down" />
          </button>

          <div class="js-sources-dropdown dropdown-menu">
            <li v-for="asset in assets.sources" :key="asset.url">
              <gl-link :href="asset.url">{{ __('Download') }} {{ asset.format }}</gl-link>
            </li>
          </div>
        </div>
      </div>

      <evidence-block v-if="hasEvidence && shouldShowEvidence" :release="release" />

      <div class="card-text prepend-top-default">
        <div v-html="release.description_html"></div>
      </div>
    </div>

    <release-block-footer
      v-if="shouldShowFooter"
      class="card-footer"
      :commit="release.commit"
      :commit-path="release.commit_path"
      :tag-name="release.tag_name"
      :tag-path="release.tag_path"
      :author="release.author"
      :released-at="release.released_at"
    />
  </div>
</template>
