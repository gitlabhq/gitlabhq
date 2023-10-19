<script>
import {
  GlAvatar,
  GlBadge,
  GlButton,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from '../../router/constants';

export default {
  i18n: {
    unreleased: s__('CiCatalog|Unreleased'),
    releasedMessage: s__('CiCatalog|Released %{timeAgo} by %{author}'),
  },
  components: {
    GlAvatar,
    GlBadge,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    resource: {
      type: Object,
      required: true,
    },
  },
  computed: {
    authorName() {
      return this.latestVersion.author.name;
    },
    authorProfileUrl() {
      return this.latestVersion.author.webUrl;
    },
    entityId() {
      return getIdFromGraphQLId(this.resource.id);
    },
    starCount() {
      return this.resource?.starCount || 0;
    },
    forksCount() {
      return this.resource?.forksCount || 0;
    },
    hasReleasedVersion() {
      return Boolean(this.latestVersion?.releasedAt);
    },
    formattedDate() {
      return formatDate(this.latestVersion?.releasedAt);
    },
    latestVersion() {
      return this.resource?.latestVersion || {};
    },
    releasedAt() {
      return getTimeago().format(this.latestVersion?.releasedAt);
    },
    resourcePath() {
      return `${this.resource.rootNamespace?.name} / ${this.resource.rootNamespace?.fullPath} / `;
    },
    tagName() {
      return this.latestVersion?.tagName || this.$options.i18n.unreleased;
    },
  },
  methods: {
    navigateToDetailsPage() {
      this.$router.push({
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: { id: this.entityId },
      });
    },
  },
};
</script>
<template>
  <li
    class="gl-display-flex gl-display-flex-wrap gl-border-b-1 gl-border-gray-100 gl-border-b-solid gl-text-gray-500 gl-py-3"
    data-testid="catalog-resource-item"
  >
    <gl-avatar
      class="gl-mr-4"
      :entity-id="entityId"
      :entity-name="resource.name"
      shape="rect"
      :size="48"
      :src="resource.icon"
      @click="navigateToDetailsPage"
    />
    <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1">
      <div class="gl-display-flex gl-flex-wrap gl-gap-2 gl-mb-2">
        <gl-button
          variant="link"
          class="gl-text-gray-900! gl-mr-1"
          data-testid="ci-resource-link"
          @click="navigateToDetailsPage"
        >
          {{ resourcePath }} <b> {{ resource.name }}</b>
        </gl-button>
        <div class="gl-display-flex gl-flex-grow-1 gl-md-justify-content-space-between">
          <gl-badge size="sm">{{ tagName }}</gl-badge>
          <span class="gl-display-flex gl-align-items-center gl-ml-5">
            <span class="gl--flex-center" data-testid="stats-favorites">
              <gl-icon name="star" :size="14" class="gl-mr-1" />
              <span class="gl-mr-3">{{ starCount }}</span>
            </span>
            <span class="gl--flex-center" data-testid="stats-forks">
              <gl-icon name="fork" :size="14" class="gl-mr-1" />
              <span>{{ forksCount }}</span>
            </span>
          </span>
        </div>
      </div>
      <div class="gl-display-flex gl-sm-flex-direction-column gl-justify-content-space-between">
        <span class="gl-display-flex gl-flex-basis-two-thirds gl-font-sm">{{
          resource.description
        }}</span>
        <div class="gl-display-flex gl-justify-content-end">
          <span v-if="hasReleasedVersion">
            <gl-sprintf :message="$options.i18n.releasedMessage">
              <template #timeAgo>
                <span v-gl-tooltip.bottom :title="formattedDate">
                  {{ releasedAt }}
                </span>
              </template>
              <template #author>
                <gl-link :href="authorProfileUrl" data-testid="user-link">
                  <span>{{ authorName }}</span>
                </gl-link>
              </template>
            </gl-sprintf>
          </span>
        </div>
      </div>
    </div>
  </li>
</template>
