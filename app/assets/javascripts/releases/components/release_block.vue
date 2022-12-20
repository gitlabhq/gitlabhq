<script>
import { isEmpty } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { scrollToElement } from '~/lib/utils/common_utils';
import { slugify } from '~/lib/utils/text_utility';
import { getLocationHash } from '~/lib/utils/url_utility';
import { CREATED_ASC } from '~/releases/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import EvidenceBlock from './evidence_block.vue';
import ReleaseBlockAssets from './release_block_assets.vue';
import ReleaseBlockFooter from './release_block_footer.vue';
import ReleaseBlockHeader from './release_block_header.vue';
import ReleaseBlockMilestoneInfo from './release_block_milestone_info.vue';

export default {
  name: 'ReleaseBlock',
  components: {
    EvidenceBlock,
    ReleaseBlockAssets,
    ReleaseBlockFooter,
    ReleaseBlockHeader,
    ReleaseBlockMilestoneInfo,
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
};
</script>
<template>
  <div :id="htmlId" :class="{ 'bg-line-target-blue': isHighlighted }" class="card release-block">
    <release-block-header :release="release" />
    <div class="card-body">
      <div v-if="shouldRenderMilestoneInfo">
        <!-- TODO: Switch open* links to opened* once fields have been updated in GraphQL -->
        <release-block-milestone-info
          :milestones="milestones"
          :opened-issues-path="release._links.openedIssuesUrl"
          :closed-issues-path="release._links.closedIssuesUrl"
          :opened-merge-requests-path="release._links.openedMergeRequestsUrl"
          :merged-merge-requests-path="release._links.mergedMergeRequestsUrl"
          :closed-merge-requests-path="release._links.closedMergeRequestsUrl"
        />
        <hr class="mb-3 mt-0" />
      </div>

      <release-block-assets v-if="shouldRenderAssets" :assets="assets" />
      <evidence-block v-if="hasEvidence" :release="release" />

      <div ref="gfm-content" class="card-text gl-mt-3">
        <div v-safe-html:[$options.safeHtmlConfig]="release.descriptionHtml" class="md"></div>
      </div>
    </div>

    <release-block-footer
      class="card-footer"
      :commit="release.commit"
      :commit-path="release.commitPath"
      :tag-name="release.tagName"
      :tag-path="release.tagPath"
      :author="release.author"
      :released-at="release.releasedAt"
      :created-at="release.createdAt"
      :sort="sort"
    />
  </div>
</template>
