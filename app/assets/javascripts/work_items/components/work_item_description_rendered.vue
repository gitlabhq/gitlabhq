<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const isCheckbox = (target) => target?.classList.contains('task-list-item-checkbox');

export default {
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    disableTruncation: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemDescription: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      truncated: false,
      checkboxes: [],
    };
  },
  computed: {
    descriptionText() {
      return this.workItemDescription?.description;
    },
    descriptionHtml() {
      return this.workItemDescription?.descriptionHtml;
    },
    isDescriptionEmpty() {
      return this.descriptionHtml?.trim() === '';
    },
    isTruncated() {
      return this.truncated && !this.disableTruncation && this.glFeatures.workItemsBeta;
    },
  },
  watch: {
    descriptionHtml: {
      handler() {
        this.renderGFM();
      },
      immediate: true,
    },
  },
  methods: {
    async renderGFM() {
      await this.$nextTick();

      renderGFM(this.$refs['gfm-content']);
      gl?.lazyLoader?.searchLazyImages();

      if (this.canEdit) {
        this.checkboxes = this.$el.querySelectorAll('.task-list-item-checkbox');

        // enable boxes, disabled by default in markdown
        this.checkboxes.forEach((checkbox) => {
          // eslint-disable-next-line no-param-reassign
          checkbox.disabled = false;
        });
      }
      this.truncateLongDescription();
    },
    toggleCheckboxes(event) {
      const { target } = event;

      if (isCheckbox(target)) {
        target.disabled = true;

        const { sourcepos } = target.parentElement.dataset;

        if (!sourcepos) return;

        const [startRange] = sourcepos.split('-');
        let [startRow] = startRange.split(':');
        startRow = Number(startRow) - 1;

        const descriptionTextRows = this.descriptionText.split('\n');
        const newDescriptionText = descriptionTextRows
          .map((row, index) => {
            if (startRow === index) {
              if (target.checked) {
                return row.replace(/\[ \]/, '[x]');
              }
              return row.replace(/\[[x~]\]/i, '[ ]');
            }
            return row;
          })
          .join('\n');

        this.$emit('descriptionUpdated', newDescriptionText);
      }
    },
    truncateLongDescription() {
      /* Truncate when description is > 40% viewport height or 512px.
         Update `.work-item-description .truncated` max height if value changes. */
      const defaultMaxHeight = window.innerHeight * 0.4;
      let maxHeight = defaultMaxHeight;
      if (defaultMaxHeight > 512) {
        maxHeight = 512;
      } else if (defaultMaxHeight < 256) {
        maxHeight = 256;
      }
      this.truncated = this.$refs['gfm-content']?.clientHeight > maxHeight;
    },
    showAll() {
      this.truncated = false;
    },
  },
};
</script>

<template>
  <div class="gl-my-5">
    <div v-if="isDescriptionEmpty" class="gl-text-secondary">{{ __('No description') }}</div>
    <div v-else ref="description" class="work-item-description md gl-clearfix gl-relative">
      <div
        ref="gfm-content"
        v-safe-html="descriptionHtml"
        data-testid="work-item-description"
        :class="{ truncated: isTruncated }"
        @change="toggleCheckboxes"
      ></div>
      <div
        v-if="isTruncated"
        class="description-more gl-block gl-w-full"
        data-test-id="description-read-more"
      >
        <div class="show-all-btn gl-w-full gl-flex gl-justify-center gl-items-center">
          <gl-button
            variant="confirm"
            category="tertiary"
            class="gl-mx-4"
            data-testid="show-all-btn"
            @click="showAll"
            >{{ __('Read more') }}</gl-button
          >
        </div>
      </div>
    </div>
  </div>
</template>
