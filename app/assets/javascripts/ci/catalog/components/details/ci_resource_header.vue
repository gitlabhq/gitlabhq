<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlCollapsibleListbox,
  GlLink,
  GlButton,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { formatDate } from '~/lib/utils/datetime_utility';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import TopicBadges from '~/vue_shared/components/topic_badges.vue';
import { VERIFICATION_LEVEL_UNVERIFIED, VISIBILITY_LEVEL_PRIVATE } from '../../constants';
import CiVerificationBadge from '../shared/ci_verification_badge.vue';
import ProjectVisibilityIcon from '../shared/project_visibility_icon.vue';
import CiResourceHeaderSkeletonLoader from './ci_resource_header_skeleton_loader.vue';

export default {
  name: 'CiResourceHeader',
  i18n: {
    moreActionsLabel: __('More actions'),
    reportAbuse: __('Report abuse'),
    lastRelease: s__('CiCatalog|Released %{date}'),
    lastReleaseMissing: s__('CiCatalog|No release available'),
  },
  components: {
    AbuseCategorySelector,
    CiResourceHeaderSkeletonLoader,
    CiVerificationBadge,
    GlAvatar,
    GlAvatarLink,
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlCollapsibleListbox,
    GlLink,
    GlButton,
    GlIcon,
    Markdown,
    ProjectVisibilityIcon,
    TopicBadges,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['reportAbusePath'],
  props: {
    isLoadingData: {
      type: Boolean,
      required: true,
    },
    resource: {
      type: Object,
      required: true,
    },
    versions: {
      type: Array,
      required: true,
    },
    initialVersionId: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['version-selected'],
  data() {
    return {
      isReportAbuseDrawerOpen: false,
      selectedVersionId: null,
    };
  },
  computed: {
    authorId() {
      return this.hasVersion && this.currentVersion?.author?.state === 'active'
        ? getIdFromGraphQLId(this.currentVersion?.author?.id)
        : 0;
    },
    entityId() {
      return getIdFromGraphQLId(this.resource.id);
    },
    hasVersion() {
      return this.currentVersion?.name;
    },
    hasTopics() {
      return this.resource?.topics?.length;
    },
    isProjectPrivate() {
      return this.resource?.visibilityLevel === VISIBILITY_LEVEL_PRIVATE;
    },
    isVerified() {
      return this.resource?.verificationLevel !== VERIFICATION_LEVEL_UNVERIFIED;
    },
    lastReleaseText() {
      if (this.currentVersion?.createdAt) {
        const date = formatDate(this.currentVersion.createdAt);
        return sprintf(this.$options.i18n.lastRelease, { date });
      }

      return this.$options.i18n.lastReleaseMissing;
    },
    currentVersion() {
      return this.resource?.versions?.nodes[0] || {};
    },
    reportedFromUrl() {
      return window.location.href;
    },
    versionBadgeText() {
      return this.currentVersion.name;
    },
    webPath() {
      return cleanLeadingSeparator(this.resource?.webPath);
    },
    isArchived() {
      return Boolean(this.resource.archived);
    },
    selectedVersion() {
      return this.versions.find((v) => v.value === this.selectedVersionId) || {};
    },
    isLatestVersion() {
      return this.versions.length > 0 && this.versions[0].text === this.currentVersion.name;
    },
    versionBadgeVariant() {
      return this.isLatestVersion ? 'info' : 'neutral';
    },
    toggleButtonText() {
      if (this.selectedVersion.text) {
        return this.selectedVersion.text;
      }
      if (this.isLoadingData) {
        return __('Loading');
      }
      return s__('CiCatalog|No versions available');
    },
  },
  watch: {
    initialVersionId: {
      immediate: true,
      handler(versionId) {
        if (versionId) {
          this.selectedVersionId = versionId;
        }
      },
    },
  },
  methods: {
    onAbuseButtonClicked() {
      this.toggleReportAbuseDrawer(true);
    },
    toggleReportAbuseDrawer(isOpen) {
      this.isReportAbuseDrawerOpen = isOpen;
    },
    onVersionSelect(versionId) {
      const version = this.versions.find((v) => v.value === versionId);
      if (version) {
        this.$router.push({
          query: { ...this.$route.query, version: version.text },
        });
        this.$emit('version-selected', version.text);
      }
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-flex gl-justify-between gl-py-5">
      <ci-resource-header-skeleton-loader v-if="isLoadingData" />
      <div v-else class="gl-flex">
        <gl-avatar-link :href="resource.webPath">
          <gl-avatar
            class="gl-mr-4"
            :entity-id="entityId"
            :entity-name="resource.name"
            :alt="resource.name"
            shape="rect"
            :size="64"
            :src="resource.icon"
          />
        </gl-avatar-link>
        <div class="gl-flex gl-flex-col gl-flex-wrap gl-items-start gl-justify-center gl-gap-4">
          <div class="gl-text-sm gl-text-subtle">
            {{ webPath }}
          </div>
          <span class="gl-flex gl-items-center gl-gap-3">
            <gl-link
              class="gl-text-lg gl-font-bold gl-text-default hover:gl-text-default"
              :href="resource.webPath"
            >
              {{ resource.name }}
            </gl-link>
            <project-visibility-icon v-if="isProjectPrivate" />
            <gl-badge
              v-if="hasVersion"
              v-gl-tooltip
              class="gl-my-1"
              :variant="versionBadgeVariant"
              data-testid="current-version-badge"
              :href="currentVersion.path"
              :title="lastReleaseText"
            >
              {{ versionBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="isArchived"
              data-testid="archive-badge"
              class="gl-my-1"
              variant="info"
              >{{ __('Archived') }}</gl-badge
            >
          </span>
          <ci-verification-badge
            v-if="isVerified"
            :verification-level="resource.verificationLevel"
            :resource-id="resource.id"
            show-text
          />
        </div>
      </div>
      <div class="gl-ml-auto">
        <gl-collapsible-listbox
          v-model="selectedVersionId"
          :items="versions"
          @select="onVersionSelect"
        >
          <template #toggle>
            <gl-button
              :disabled="!selectedVersion.text"
              :loading="isLoadingData && !selectedVersion.text"
            >
              <span>{{ toggleButtonText }}</span>
              <span v-if="selectedVersion.createdAt" class="gl-text-sm gl-text-secondary"
                >({{ selectedVersion.createdAt }})
              </span>
              <gl-icon name="chevron-down" class="gl-ml-2" />
            </gl-button>
          </template>
          <template #list-item="{ item }">
            <span>{{ item.text }}</span>
            <span class="gl-text-sm gl-text-secondary">({{ item.createdAt }})</span>
          </template>
        </gl-collapsible-listbox>
        <gl-disclosure-dropdown
          v-gl-tooltip
          :title="$options.i18n.moreActionsLabel"
          :toggle-text="$options.i18n.moreActionsLabel"
          :disabled="isLoadingData"
          text-sr-only
          icon="ellipsis_v"
          category="tertiary"
          placement="bottom-end"
          class="note-action-button more-actions-toggle"
          no-caret
        >
          <gl-disclosure-dropdown-item
            data-testid="report-abuse-button"
            @action="onAbuseButtonClicked"
          >
            <template #list-item>
              {{ $options.i18n.reportAbuse }}
            </template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown>
      </div>
    </div>
    <div
      v-if="isLoadingData"
      class="gl-animate-skeleton-loader gl-my-3 gl-h-4 !gl-max-w-20 gl-rounded-base"
    ></div>
    <markdown v-else-if="resource.description" class="gl-mb-3" :markdown="resource.description" />
    <topic-badges v-if="hasTopics" :topics="resource.topics" :show-label="false" class="gl-mb-5" />
    <abuse-category-selector
      v-if="hasVersion && isReportAbuseDrawerOpen && reportAbusePath"
      :reported-user-id="authorId"
      :reported-from-url="reportedFromUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
