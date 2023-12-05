<script>
import { GlAvatar, GlBadge, GlIcon, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from '../../router/constants';

export default {
  i18n: {
    unreleased: s__('CiCatalog|Unreleased'),
    releasedMessage: s__('CiCatalog|Released %{timeAgo} by %{author}'),
  },
  components: {
    GlAvatar,
    GlBadge,
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
    resourceId() {
      return cleanLeadingSeparator(this.resource.webPath);
    },
    detailsPageResolved() {
      return this.$router.resolve({
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: { id: this.resourceId },
      });
    },
    detailsPageHref() {
      return decodeURIComponent(this.detailsPageResolved.href);
    },
    entityId() {
      return getIdFromGraphQLId(this.resource.id);
    },
    starCount() {
      return this.resource?.starCount || 0;
    },
    starCountText() {
      return n__('Star', 'Stars', this.starCount);
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
    tagName() {
      return this.latestVersion?.tagName || this.$options.i18n.unreleased;
    },
    webPath() {
      return cleanLeadingSeparator(this.resource?.webPath);
    },
  },
  methods: {
    navigateToDetailsPage(e) {
      // Open link in a new tab if any of these modifier key is held down.
      if (e?.ctrlKey || e?.metaKey) {
        return;
      }

      // Override the <a> tag if no modifier key is held down to use Vue router and not
      // open a new tab.
      e.preventDefault();

      // Push to the decoded URL to avoid all the / being encoded
      this.$router.push({ path: decodeURIComponent(this.resourceId) });
    },
  },
};
</script>
<template>
  <li
    class="gl-display-flex gl-display-flex-wrap gl-align-items-center gl-border-b-1 gl-border-gray-100 gl-border-b-solid gl-text-gray-500 gl-py-3"
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
      <span class="gl-font-sm gl-mb-1">{{ webPath }}</span>
      <div class="gl-display-flex gl-flex-wrap gl-gap-2 gl-mb-1">
        <gl-link
          class="gl-text-gray-900! gl-mr-1"
          :href="detailsPageHref"
          data-testid="ci-resource-link"
          @click="navigateToDetailsPage"
        >
          <b> {{ resource.name }}</b>
        </gl-link>
        <div class="gl-display-flex gl-flex-grow-1 gl-md-justify-content-space-between">
          <gl-badge size="sm" class="gl-h-5 gl-align-self-center">{{ tagName }}</gl-badge>
          <span class="gl-display-flex gl-align-items-center gl-ml-5">
            <span
              v-gl-tooltip.top
              :title="starCountText"
              class="gl--flex-center"
              data-testid="stats-favorites"
            >
              <gl-icon name="star-o" :size="14" class="gl-mr-2" />
              <span class="gl-mr-3">{{ starCount }}</span>
            </span>
          </span>
        </div>
      </div>
      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-justify-content-space-between gl-font-sm"
      >
        <span class="gl-display-flex gl-flex-basis-two-thirds">{{ resource.description }}</span>
        <div class="gl-display-flex gl-justify-content-end">
          <span v-if="hasReleasedVersion">
            <gl-sprintf :message="$options.i18n.releasedMessage">
              <template #timeAgo>
                <span v-gl-tooltip.top :title="formattedDate">
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
