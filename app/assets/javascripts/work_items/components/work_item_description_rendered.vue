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
    disableInlineEditing: {
      type: Boolean,
      required: false,
      default: false,
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
    descriptionEmpty() {
      return this.descriptionHtml?.trim() === '';
    },
    showEmptyDescription() {
      return this.descriptionEmpty && !this.disableInlineEditing;
    },
    showEditButton() {
      return this.canEdit && !this.disableInlineEditing;
    },
    isTruncated() {
      return this.truncated && !this.disableTruncation && this.glFeatures.workItemsMvc2;
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
      const defaultMaxHeight = document.documentElement.clientHeight * 0.4;
      let maxHeight = defaultMaxHeight;
      if (defaultMaxHeight > 512) {
        maxHeight = 512;
      } else if (defaultMaxHeight < 256) {
        maxHeight = 256;
      }
      this.truncated = this.$refs['gfm-content'].clientHeight > maxHeight;
    },
    showAll() {
      this.truncated = false;
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <div class="gl-display-inline-flex gl-align-items-center gl-mb-3">
      <label v-if="!disableInlineEditing" class="d-block col-form-label gl-mr-5">{{
        __('Description')
      }}</label>
      <gl-button
        v-if="showEditButton"
        v-gl-tooltip
        class="gl-ml-auto"
        icon="pencil"
        data-testid="edit-description"
        :aria-label="__('Edit description')"
        :title="__('Edit description')"
        @click="$emit('startEditing')"
      />
    </div>

    <div v-if="showEmptyDescription" class="gl-text-secondary gl-mb-5">{{ __('None') }}</div>
    <div
      v-else-if="!descriptionEmpty"
      ref="description"
      class="work-item-description md gl-mb-5 gl-min-h-8 gl-clearfix gl-relative"
    >
      <div
        ref="gfm-content"
        v-safe-html="descriptionHtml"
        data-testid="work-item-description"
        :class="{ truncated: isTruncated }"
        @change="toggleCheckboxes"
      ></div>
      <div
        v-if="isTruncated"
        class="description-more gl-display-block gl-w-full"
        data-test-id="description-read-more"
      >
        <div class="show-all-btn gl-w-full gl--flex-center">
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
