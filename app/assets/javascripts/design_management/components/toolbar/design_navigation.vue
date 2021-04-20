<script>
/* global Mousetrap */
import 'mousetrap';
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import {
  keysFor,
  ISSUE_PREVIOUS_DESIGN,
  ISSUE_NEXT_DESIGN,
} from '~/behaviors/shortcuts/keybindings';
import { s__, sprintf } from '~/locale';
import allDesignsMixin from '../../mixins/all_designs';
import { DESIGN_ROUTE_NAME } from '../../router/constants';

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
  mixins: [allDesignsMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  computed: {
    designsCount() {
      return this.designs.length;
    },
    currentIndex() {
      return this.designs.findIndex((design) => design.filename === this.id);
    },
    paginationText() {
      return sprintf(s__('DesignManagement|%{current_design} of %{designs_count}'), {
        current_design: this.currentIndex + 1,
        designs_count: this.designsCount,
      });
    },
    previousDesign() {
      if (this.currentIndex === 0) return null;

      return this.designs[this.currentIndex - 1];
    },
    nextDesign() {
      if (this.currentIndex + 1 === this.designsCount) return null;

      return this.designs[this.currentIndex + 1];
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
          name: DESIGN_ROUTE_NAME,
          params: { id: design.filename },
          query: this.$route.query,
        });
      }
    },
  },
};
</script>

<template>
  <div v-if="designsCount" class="gl-display-flex gl-align-items-center">
    {{ paginationText }}
    <gl-button-group class="gl-mx-5">
      <gl-button
        v-gl-tooltip.bottom
        :disabled="!previousDesign"
        :title="$options.i18n.previousButton"
        :aria-label="$options.i18n.previousButton"
        icon="angle-left"
        class="js-previous-design"
        @click="navigateToDesign(previousDesign)"
      />
      <gl-button
        v-gl-tooltip.bottom
        :disabled="!nextDesign"
        :title="$options.i18n.nextButton"
        :aria-label="$options.i18n.nextButton"
        icon="angle-right"
        class="js-next-design"
        @click="navigateToDesign(nextDesign)"
      />
    </gl-button-group>
  </div>
</template>
