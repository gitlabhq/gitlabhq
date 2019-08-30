<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import _ from 'underscore';
import { GlTooltipDirective, GlLink, GlBadge } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { __, sprintf } from '../../locale';

export default {
  name: 'ReleaseBlock',
  components: {
    GlLink,
    GlBadge,
    Icon,
    UserAvatarLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    release: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  computed: {
    releasedTimeAgo() {
      return sprintf(__('released %{time}'), {
        time: this.timeFormated(this.release.released_at),
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
    assets() {
      return this.release.assets || {};
    },
    author() {
      return this.release.author || {};
    },
    hasAuthor() {
      return !_.isEmpty(this.author);
    },
  },
};
</script>
<template>
  <div :id="release.tag_name" class="card">
    <div class="card-body">
      <h2 class="card-title mt-0">
        {{ release.name }}
        <gl-badge v-if="release.upcoming_release" variant="warning" class="align-middle">{{
          __('Upcoming Release')
        }}</gl-badge>
      </h2>

      <div class="card-subtitle d-flex flex-wrap text-secondary">
        <div class="append-right-8">
          <icon name="commit" class="align-middle" />
          <span v-gl-tooltip.bottom :title="commit.title">{{ commit.short_id }}</span>
        </div>

        <div class="append-right-8">
          <icon name="tag" class="align-middle" />
          <span v-gl-tooltip.bottom :title="__('Tag')">{{ release.tag_name }}</span>
        </div>

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
            :link-href="author.path"
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

      <div class="card-text prepend-top-default">
        <div v-html="release.description_html"></div>
      </div>
    </div>
  </div>
</template>
