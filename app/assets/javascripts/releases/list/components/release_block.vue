<script>
import _ from 'underscore';
import { slugify } from '~/lib/utils/text_utility';
import { getLocationHash } from '~/lib/utils/url_utility';
import { scrollToElement } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
    id() {
      return slugify(this.release.tag_name);
    },
    assets() {
      return this.release.assets || {};
    },
    hasEvidence() {
      return Boolean(this.release.evidence_sha);
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
    <release-block-header :release="release" />
    <div class="card-body">
      <div v-if="shouldRenderMilestoneInfo">
        <release-block-milestone-info :milestones="milestones" />
        <hr class="mb-3 mt-0" />
      </div>

      <release-block-metadata v-if="shouldRenderReleaseMetaData" :release="release" />
      <release-block-assets v-if="shouldRenderAssets" :assets="assets" />
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
