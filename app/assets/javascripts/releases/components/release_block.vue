<script>
import { GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash-es';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { slugify } from '~/lib/utils/text_utility';
import { getLocationHash, setUrlParams } from '~/lib/utils/url_utility';
import { BACK_URL_PARAM, CREATED_ASC } from '~/releases/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __, sprintf } from '~/locale';
import EvidenceBlock from './evidence_block.vue';
import ReleaseBlockAssets from './release_block_assets.vue';
import ReleaseBlockDetails from './release_block_details.vue';
import ReleaseBlockTitle from './release_block_title.vue';
import ReleaseBlockMilestoneInfo from './release_block_milestone_info.vue';
import ReleaseBlockDeployments from './release_block_deployments.vue';

export default {
  name: 'ReleaseBlock',
  components: {
    GlButton,
    CrudComponent,
    EvidenceBlock,
    ReleaseBlockAssets,
    ReleaseBlockTitle,
    ReleaseBlockMilestoneInfo,
    ReleaseBlockDeployments,
    ReleaseBlockDetails,
  },
  directives: {
    SafeHtml,
  },
  props: {
    release: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    sort: {
      type: String,
      required: false,
      default: CREATED_ASC,
    },
    deployments: {
      type: Array,
      required: false,
      default: () => [],
    },
    previousReleaseSha: {
      type: String,
      required: false,
      default: '',
    },
    comparePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isHighlighted: false,
    };
  },
  computed: {
    htmlId() {
      if (!this.release.tagName) {
        return null;
      }

      return slugify(this.release.tagName);
    },
    assets() {
      return this.release.assets || {};
    },
    hasEvidence() {
      return Boolean(this.release.evidences && this.release.evidences.length);
    },
    milestones() {
      return this.release.milestones || [];
    },
    links() {
      return this.release._links || {};
    },
    shouldRenderAssets() {
      return Boolean(
        this.assets.links.length || (this.assets.sources && this.assets.sources.length),
      );
    },
    shouldRenderMilestoneInfo() {
      return Boolean(!isEmpty(this.release.milestones));
    },
    editLink() {
      if (this.links.editUrl) {
        const queryParams = {
          [BACK_URL_PARAM]: window.location.href,
        };

        return setUrlParams(queryParams, { url: this.links.editUrl });
      }

      return undefined;
    },
    shouldApplyDeploymentsBlockCss() {
      return Boolean(this.shouldRenderAssets || this.hasEvidence || this.release.descriptionHtml);
    },
    shouldApplyAssetsBlockCss() {
      return Boolean(this.hasEvidence || this.release.descriptionHtml);
    },
    isFutureRelease() {
      return new Date() < new Date(this.release.releasedAt);
    },
  },

  mounted() {
    this.renderGFM();

    const hash = getLocationHash();
    if (hash && slugify(hash) === this.htmlId) {
      this.isHighlighted = true;
      setTimeout(() => {
        this.isHighlighted = false;
      }, 2000);

      scrollToElement(this.$el);
    }
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs['gfm-content']);
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  i18n: {
    editButton: __('Edit release'),
    editButtonAriaLabel: (title) => sprintf(__('Edit release (%{title})'), { title }),
  },
  commonCssClasses: 'gl-border-b-1 gl-pb-5 gl-border-b-solid gl-border-default',
};
</script>
<template>
  <crud-component
    :id="htmlId"
    v-bind="$attrs"
    class="gl-mt-5"
    :is-highlighted="isHighlighted"
    :class="{ '!gl-bg-feedback-info': isHighlighted }"
    data-testid="release-block"
  >
    <template #title>
      <release-block-title
        :release="release"
        :commit="release.commit"
        :commit-path="release.commitPath"
        :tag-name="release.tagName"
        :tag-path="release.tagPath"
        :author="release.author"
        :released-at="release.releasedAt"
        :created-at="release.createdAt"
        :sort="sort"
      />
    </template>

    <template #actions>
      <gl-button
        v-if="editLink"
        category="primary"
        size="small"
        variant="default"
        class="js-edit-button"
        :aria-label="$options.i18n.editButtonAriaLabel(release.name)"
        :href="editLink"
      >
        {{ $options.i18n.editButton }}
      </gl-button>
    </template>

    <div class="gl-flex gl-flex-col gl-gap-5 gl-px-5 gl-py-4 @md:gl-flex-row">
      <release-block-details
        :author="release.author"
        :commit-path="release.commitPath"
        :commit="release.commit"
        :compare-path="comparePath"
        :created-at="release.createdAt"
        :previous-release-sha="previousReleaseSha"
        :released-at="release.releasedAt"
        :sort="sort"
        :tag-name="release.tagName"
        :tag-path="release.tagPath"
      />
      <div class="gl-flex gl-grow gl-flex-col gl-gap-5">
        <div v-if="release.descriptionHtml" ref="gfm-content" :class="$options.commonCssClasses">
          <h3 class="gl-heading-3 !gl-mb-2 gl-mt-0">{{ __('Release notes') }}</h3>
          <div
            v-safe-html:[$options.safeHtmlConfig]="release.descriptionHtml"
            class="md"
            data-testid="release-description"
          ></div>
        </div>

        <div
          v-if="shouldRenderMilestoneInfo"
          class="gl-border-b-1 gl-border-default gl-border-b-solid"
        >
          <!-- TODO: Switch open* links to opened* once fields have been updated in GraphQL -->
          <release-block-milestone-info
            :milestones="milestones"
            :show-details="isFutureRelease"
            :opened-issues-path="links.openedIssuesUrl"
            :closed-issues-path="links.closedIssuesUrl"
            :opened-merge-requests-path="links.openedMergeRequestsUrl"
            :merged-merge-requests-path="links.mergedMergeRequestsUrl"
            :closed-merge-requests-path="links.closedMergeRequestsUrl"
          />
        </div>

        <release-block-deployments
          v-if="deployments.length"
          :class="{
            [`${$options.commonCssClasses}`]: shouldApplyDeploymentsBlockCss,
          }"
          :deployments="deployments"
        />

        <release-block-assets
          v-if="shouldRenderAssets"
          :assets="assets"
          :expanded="!deployments.length"
          :class="{
            [`${$options.commonCssClasses}`]: shouldApplyAssetsBlockCss,
          }"
        />
        <evidence-block v-if="hasEvidence" :release="release" />
      </div>
    </div>
  </crud-component>
</template>
