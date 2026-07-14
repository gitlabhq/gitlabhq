<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormCheckbox,
  GlDropdownDivider,
  GlToggle,
  GlTooltipDirective,
} from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { getParameterByName, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import AccessorUtilities from '~/lib/utils/accessor';

const SHOW_AGE_INDICATOR_KEY = 'blame_show_age_indicator';

const i18n = {
  blamePreferences: s__('Blame|Blame preferences'),
  showAgeIndicator: s__('Blame|Show age indicator legend'),
  ignoreSpecificRevs: s__('Blame|Ignore specific revisions'),
  learnToIgnore: s__('Blame|Learn to ignore specific revisions'),
};

export default {
  name: 'BlamePreferences',
  i18n,
  docsLink: helpPagePath('user/project/repository/files/git_blame.md', {
    anchor: 'ignore-specific-revisions',
  }),
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlFormCheckbox,
    GlDropdownDivider,
    GlToggle,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    hasRevsFile: {
      type: Boolean,
      required: true,
    },
    showAgeIndicatorToggle: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  emits: ['toggle-age-indicator'],
  data() {
    return {
      isIgnoring: parseBoolean(getParameterByName('ignore_revs')),
      isLoading: false,
      showAgeIndicator: false,
    };
  },
  created() {
    this.showAgeIndicator = this.loadShowAgeIndicator();
  },
  mounted() {
    this.$emit('toggle-age-indicator', this.showAgeIndicator);
  },
  methods: {
    loadShowAgeIndicator() {
      if (!AccessorUtilities.canUseLocalStorage()) return false;
      return localStorage.getItem(SHOW_AGE_INDICATOR_KEY) === 'true';
    },
    toggleAgeIndicator() {
      this.showAgeIndicator = !this.showAgeIndicator;
      if (AccessorUtilities.canUseLocalStorage()) {
        localStorage.setItem(SHOW_AGE_INDICATOR_KEY, String(this.showAgeIndicator));
      }
      this.trackEvent('toggle_inline_blame_age_indicator_on_blob_page', {
        property: this.showAgeIndicator ? 'show' : 'hide',
      });
      this.$emit('toggle-age-indicator', this.showAgeIndicator);
    },
    toggleIgnoreRevs() {
      this.isIgnoring = !this.isIgnoring;
      this.isLoading = true;
      visitUrl(setUrlParams({ ignore_revs: this.isIgnoring }));
    },
    visitDocs() {
      visitUrl(this.$options.docsLink);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.hover
    :title="$options.i18n.blamePreferences"
    :toggle-text="$options.i18n.blamePreferences"
    :loading="isLoading"
    :auto-close="false"
    icon="preferences"
    text-sr-only
    placement="bottom-end"
  >
    <template #header>
      <div class="gl-border-b gl-p-4 gl-font-bold">
        {{ $options.i18n.blamePreferences }}
      </div>
    </template>
    <template v-if="showAgeIndicatorToggle">
      <gl-disclosure-dropdown-item data-testid="age-indicator-toggle">
        <template #list-item>
          <gl-toggle
            :value="showAgeIndicator"
            :label="$options.i18n.showAgeIndicator"
            class="gl-justify-between [&_.gl-toggle-label]:gl-font-normal"
            label-position="left"
            @change="toggleAgeIndicator"
          />
        </template>
      </gl-disclosure-dropdown-item>

      <gl-dropdown-divider />
    </template>

    <template v-if="!hasRevsFile">
      <div class="gl-m-3">
        <gl-disclosure-dropdown-item data-testid="learn-to-ignore-item" @action="visitDocs">{{
          $options.i18n.learnToIgnore
        }}</gl-disclosure-dropdown-item>
      </div>
    </template>

    <template v-else>
      <gl-disclosure-dropdown-item data-testid="ignore-revs-item" @action="toggleIgnoreRevs">
        <template #list-item>
          <gl-form-checkbox
            :checked="isIgnoring"
            class="gl-pointer-events-none -gl-mb-3"
            data-testid="ignore-revs-checkbox"
            >{{ $options.i18n.ignoreSpecificRevs }}</gl-form-checkbox
          >
        </template>
      </gl-disclosure-dropdown-item>

      <gl-dropdown-divider />
      <gl-disclosure-dropdown-item
        class="gl-p-4"
        data-testid="learn-to-ignore-item"
        @action="visitDocs"
        >{{ $options.i18n.learnToIgnore }}</gl-disclosure-dropdown-item
      >
    </template>
  </gl-disclosure-dropdown>
</template>
