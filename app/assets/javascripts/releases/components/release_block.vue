<script>
import { GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { scrollToElement } from '~/lib/utils/common_utils';
import { slugify } from '~/lib/utils/text_utility';
import { getLocationHash, setUrlParams } from '~/lib/utils/url_utility';
import { BACK_URL_PARAM, CREATED_ASC } from '~/releases/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __ } from '~/locale';
import EvidenceBlock from './evidence_block.vue';
import ReleaseBlockAssets from './release_block_assets.vue';
import ReleaseBlockFooter from './release_block_footer.vue';
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
    ReleaseBlockFooter,
    ReleaseBlockTitle,
    ReleaseBlockMilestoneInfo,
    ReleaseBlockDeployments,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
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
    shouldRenderAssets() {
      return Boolean(
        this.assets.links.length || (this.assets.sources && this.assets.sources.length),
      );
    },
    shouldRenderMilestoneInfo() {
      return Boolean(!isEmpty(this.release.milestones));
    },
    editLink() {
      if (this.release._links?.editUrl) {
        const queryParams = {
          [BACK_URL_PARAM]: window.location.href,
        };

        return setUrlParams(queryParams, this.release._links.editUrl);
      }

      return undefined;
    },
    shouldApplyDeploymentsBlockCss() {
      return Boolean(this.shouldRenderAssets || this.hasEvidence || this.release.descriptionHtml);
    },
    shouldApplyAssetsBlockCss() {
      return Boolean(this.hasEvidence || this.release.descriptionHtml);
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
  },
  commonCssClasses: 'gl-border-b-1 gl-pb-5 gl-border-b-solid',
};
</script>
<template>
  <crud-component
    :id="htmlId"
    v-bind="$attrs"
    class="gl-mt-5"
    :is-highlighted="isHighlighted"
    :class="{ 'bg-line-target-blue': isHighlighted }"
    data-testid="release-block"
  >
    <template #title>
      <release-block-title :release="release" />
    </template>

    <template #actions>
      <gl-button
        v-if="editLink"
        category="primary"
        size="small"
        variant="default"
        class="js-edit-button"
        :href="editLink"
      >
        {{ $options.i18n.editButton }}
      </gl-button>
    </template>

    <div class="gl-mx-5 gl-my-4 gl-flex gl-flex-col gl-gap-5">
      <div
        v-if="shouldRenderMilestoneInfo"
        class="gl-border-b-1 gl-border-default gl-border-b-solid"
      >
        <!-- TODO: Switch open* links to opened* once fields have been updated in GraphQL -->
        <release-block-milestone-info
          :milestones="milestones"
          :opened-issues-path="release._links.openedIssuesUrl"
          :closed-issues-path="release._links.closedIssuesUrl"
          :opened-merge-requests-path="release._links.openedMergeRequestsUrl"
          :merged-merge-requests-path="release._links.mergedMergeRequestsUrl"
          :closed-merge-requests-path="release._links.closedMergeRequestsUrl"
        />
      </div>

      <release-block-deployments
        v-if="deployments.length"
        :class="{
          [`${$options.commonCssClasses} gl-border-gray-100`]: shouldApplyDeploymentsBlockCss,
        }"
        :deployments="deployments"
      />

      <release-block-assets
        v-if="shouldRenderAssets"
        :assets="assets"
        :expanded="!deployments.length"
        :class="{
          [`${$options.commonCssClasses} gl-border-default`]: shouldApplyAssetsBlockCss,
        }"
      />
      <evidence-block v-if="hasEvidence" :release="release" />

      <div v-if="release.descriptionHtml" ref="gfm-content">
        <h3 class="gl-heading-5 !gl-mb-2">{{ __('Release notes') }}</h3>
        <div
          v-safe-html:[$options.safeHtmlConfig]="release.descriptionHtml"
          class="md"
          data-testid="release-description"
        ></div>
      </div>
    </div>

    <template #footer>
      <release-block-footer
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
  </crud-component>
</template>
