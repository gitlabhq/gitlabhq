<script>
import { s__, n__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'MRWidgetRelatedLinks',
  mixins: [glFeatureFlagMixin()],
  props: {
    relatedLinks: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    state: {
      type: String,
      required: false,
      default: '',
    },
    showAssignToMe: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    closesText() {
      if (this.state === 'merged') {
        return s__('mrWidget|Closed');
      }
      if (this.state === 'closed') {
        return s__('mrWidget|Did not close');
      }

      return n__('mrWidget|Closes issue', 'mrWidget|Closes issues', this.relatedLinks.closingCount);
    },
  },
};
</script>
<template>
  <section>
    <p
      v-if="relatedLinks.closing"
      :class="{ 'gl-display-line gl-m-0': glFeatures.restructuredMrWidget }"
    >
      {{ closesText }}
      <span v-html="relatedLinks.closing /* eslint-disable-line vue/no-v-html */"></span>
    </p>
    <p
      v-if="relatedLinks.mentioned"
      :class="{ 'gl-display-line gl-m-0': glFeatures.restructuredMrWidget }"
    >
      {{ n__('mrWidget|Mentions issue', 'mrWidget|Mentions issues', relatedLinks.mentionedCount) }}
      <span v-html="relatedLinks.mentioned /* eslint-disable-line vue/no-v-html */"></span>
    </p>
    <p
      v-if="relatedLinks.assignToMe && showAssignToMe"
      :class="{ 'gl-display-line gl-m-0': glFeatures.restructuredMrWidget }"
    >
      <span v-html="relatedLinks.assignToMe /* eslint-disable-line vue/no-v-html */"></span>
    </p>
  </section>
</template>
