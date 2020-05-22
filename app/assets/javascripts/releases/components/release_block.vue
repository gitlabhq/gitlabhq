<script>
import { isEmpty } from 'lodash';
import $ from 'jquery';
import { slugify } from '~/lib/utils/text_utility';
import { getLocationHash } from '~/lib/utils/url_utility';
import { scrollToElement } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import '~/behaviors/markdown/render_gfm';
import EvidenceBlock from './evidence_block.vue';
import ReleaseBlockAssets from './release_block_assets.vue';
import ReleaseBlockFooter from './release_block_footer.vue';
import ReleaseBlockHeader from './release_block_header.vue';
import ReleaseBlockMetadata from './release_block_metadata.vue';
import ReleaseBlockMilestoneInfo from './release_block_milestone_info.vue';

export default {
  name: 'ReleaseBlock',
  components: {
    EvidenceBlock,
    ReleaseBlockAssets,
    ReleaseBlockFooter,
    ReleaseBlockHeader,
    ReleaseBlockMetadata,
    ReleaseBlockMilestoneInfo,
  },
  mixins: [glFeatureFlagsMixin()],
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
    shouldShowEvidence() {
      return this.glFeatures.releaseEvidenceCollection;
    },
    shouldShowFooter() {
      return this.glFeatures.releaseIssueSummary;
    },
    shouldRenderAssets() {
      return Boolean(
        this.assets.links.length || (this.assets.sources && this.assets.sources.length),
      );
    },
    shouldRenderReleaseMetaData() {
      return !this.glFeatures.releaseIssueSummary;
    },
    shouldRenderMilestoneInfo() {
      return Boolean(this.glFeatures.releaseIssueSummary && !isEmpty(this.release.milestones));
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
      $(this.$refs['gfm-content']).renderGFM();
    },
  },
};
</script>
<template>
  <div :id="htmlId" :class="{ 'bg-line-target-blue': isHighlighted }" class="card release-block">
    <release-block-header :release="release" />
    <div class="card-body">
      <div v-if="shouldRenderMilestoneInfo">
        <release-block-milestone-info
          :milestones="milestones"
          :open-issues-path="release._links.issuesUrl"
        />
        <hr class="mb-3 mt-0" />
      </div>

      <release-block-metadata v-if="shouldRenderReleaseMetaData" :release="release" />
      <release-block-assets v-if="shouldRenderAssets" :assets="assets" />
      <evidence-block v-if="hasEvidence && shouldShowEvidence" :release="release" />

      <div ref="gfm-content" class="card-text prepend-top-default">
        <div class="md" v-html="release.descriptionHtml"></div>
      </div>
    </div>

    <release-block-footer
      v-if="shouldShowFooter"
      class="card-footer"
      :commit="release.commit"
      :commit-path="release.commitPath"
      :tag-name="release.tagName"
      :tag-path="release.tagPath"
      :author="release.author"
      :released-at="release.releasedAt"
    />
  </div>
</template>
