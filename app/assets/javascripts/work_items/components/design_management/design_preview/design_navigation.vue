<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import {
  keysFor,
  ISSUE_PREVIOUS_DESIGN,
  ISSUE_NEXT_DESIGN,
} from '~/behaviors/shortcuts/keybindings';
import { Mousetrap } from '~/lib/mousetrap';
import { s__, sprintf } from '~/locale';
import { ROUTES } from '../../../constants';

export default {
  i18n: {
    nextButton: s__('DesignManagement|Go to next design'),
    previousButton: s__('DesignManagement|Go to previous design'),
  },
  components: {
    GlButton,
    GlButtonGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    filename: {
      type: String,
      required: true,
    },
    allDesigns: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    designsCount() {
      return this.allDesigns.length;
    },
    currentIndex() {
      return this.allDesigns.findIndex((design) => design.filename === this.filename);
    },
    paginationText() {
      return sprintf(s__('DesignManagement|of %{designs_count}'), {
        designs_count: this.designsCount,
      });
    },
    previousDesign() {
      if (this.currentIndex === 0) return null;

      return this.allDesigns[this.currentIndex - 1];
    },
    nextDesign() {
      if (this.currentIndex + 1 === this.designsCount) return null;

      return this.allDesigns[this.currentIndex + 1];
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(ISSUE_PREVIOUS_DESIGN), () =>
      this.navigateToDesign(this.previousDesign),
    );
    Mousetrap.bind(keysFor(ISSUE_NEXT_DESIGN), () => this.navigateToDesign(this.nextDesign));
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(ISSUE_PREVIOUS_DESIGN));
    Mousetrap.unbind(keysFor(ISSUE_NEXT_DESIGN));
  },
  methods: {
    navigateToDesign(design) {
      if (design) {
        this.$router.push({
          name: ROUTES.design,
          params: { id: design.filename },
          query: this.$route.query,
        });
      }
    },
  },
};
</script>

<template>
  <div v-if="designsCount" class="gl-flex gl-shrink-0 gl-items-center">
    <div class="gl-mr-2 gl-w-5 gl-text-right">{{ currentIndex + 1 }}</div>
    <div>{{ paginationText }}</div>
    <gl-button-group class="gl-ml-3">
      <gl-button
        v-gl-tooltip.bottom
        :disabled="!previousDesign"
        :title="$options.i18n.previousButton"
        :aria-label="$options.i18n.previousButton"
        icon="chevron-lg-left"
        class="js-previous-design"
        @click="navigateToDesign(previousDesign)"
      />
      <gl-button
        v-gl-tooltip.bottom
        :disabled="!nextDesign"
        :title="$options.i18n.nextButton"
        :aria-label="$options.i18n.nextButton"
        icon="chevron-lg-right"
        class="js-next-design"
        @click="navigateToDesign(nextDesign)"
      />
    </gl-button-group>
  </div>
</template>
