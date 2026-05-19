<script>
import {
  GlBadge,
  GlButton,
  GlDatepicker,
  GlDisclosureDropdown,
  GlFormGroup,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { debounce } from 'lodash-es';
import { newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { queryToObject, visitUrl } from '~/lib/utils/url_utility';
import { __, n__, sprintf } from '~/locale';

const tooltipMessage = __('Searching by both date and message is currently not supported.');

export default {
  name: 'DateRangeSelect',
  components: {
    GlBadge,
    GlButton,
    GlDatepicker,
    GlDisclosureDropdown,
    GlFormGroup,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commitsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const params = queryToObject(window.location.search);
    return {
      committedAfter: params.committed_after || '',
      committedBefore: params.committed_before || '',
      hasSearchParam: Boolean(params.search),
    };
  },
  computed: {
    urlCommittedAfter() {
      return queryToObject(window.location.search).committed_after || '';
    },
    urlCommittedBefore() {
      return queryToObject(window.location.search).committed_before || '';
    },
    activeFilterCount() {
      return [this.urlCommittedAfter, this.urlCommittedBefore].filter(Boolean).length;
    },
    hasActiveFilters() {
      return this.activeFilterCount > 0;
    },
    activeFiltersLabel() {
      return sprintf(
        n__('%{count} filter applied', '%{count} filters applied', this.activeFilterCount),
        {
          count: this.activeFilterCount,
        },
      );
    },
    committedAfterDate() {
      return this.committedAfter ? newDate(this.committedAfter) : null;
    },
    committedBeforeDate() {
      return this.committedBefore ? newDate(this.committedBefore) : null;
    },
    tooltipTitle() {
      return this.hasSearchParam ? tooltipMessage : '';
    },
  },
  mounted() {
    this.commitsSearchInput = document.querySelector('#commits-search');
    if (!this.commitsSearchInput) return;

    if (this.hasActiveFilters) {
      this.commitsSearchInput.setAttribute('disabled', true);
      this.commitsSearchInput.dataset.toggle = 'tooltip';
      this.commitsSearchInput.setAttribute('title', tooltipMessage);
    }

    this.onSearchKeyup = debounce((event) => this.setSearchParam(event.target.value), 500);
    this.commitsSearchInput.addEventListener('keyup', this.onSearchKeyup);
  },
  beforeDestroy() {
    if (!this.commitsSearchInput) return;

    this.commitsSearchInput.removeEventListener('keyup', this.onSearchKeyup);
    this.onSearchKeyup.cancel();
  },
  methods: {
    onCommittedAfterInput(date) {
      this.committedAfter = date ? toISODateFormat(date) : '';
    },
    onCommittedBeforeInput(date) {
      this.committedBefore = date ? toISODateFormat(date) : '';
    },
    applyFilters() {
      const params = queryToObject(window.location.search);
      const urlParams = new URLSearchParams();

      if (params.author) urlParams.set('author', params.author);
      if (this.committedAfter) urlParams.set('committed_after', this.committedAfter);
      if (this.committedBefore) urlParams.set('committed_before', this.committedBefore);

      const qs = urlParams.toString();
      visitUrl(qs ? `${this.commitsPath}?${qs}` : this.commitsPath);
    },
    clearFilters() {
      this.committedAfter = '';
      this.committedBefore = '';

      const params = queryToObject(window.location.search);
      const urlParams = new URLSearchParams();

      if (params.author) urlParams.set('author', params.author);

      const qs = urlParams.toString();
      visitUrl(qs ? `${this.commitsPath}?${qs}` : this.commitsPath);
    },
    setSearchParam(value) {
      this.hasSearchParam = Boolean(value);
    },
  },
  i18n: {
    date: __('Date'),
    committedAfter: __('Committed after'),
    committedBefore: __('Committed before'),
    apply: __('Apply'),
    clear: __('Clear'),
  },
};
</script>

<template>
  <div
    v-gl-tooltip
    :title="tooltipTitle"
    :class="{ '!gl-cursor-not-allowed': hasSearchParam }"
    class="gl-mt-3 @md/panel:gl-mt-0"
  >
    <gl-disclosure-dropdown
      :auto-close="false"
      :disabled="hasSearchParam"
      block
      data-testid="date-range-dropdown"
    >
      <template #toggle="{ accessibilityAttributes }">
        <gl-button
          v-bind="accessibilityAttributes"
          :disabled="hasSearchParam"
          block
          button-text-classes="gl-w-full"
          class="gl-new-dropdown-toggle"
        >
          <span class="gl-mr-auto gl-inline-flex gl-items-center gl-gap-2">
            {{ $options.i18n.date }}
            <gl-badge v-if="hasActiveFilters" variant="info" class="@md/panel:gl-hidden">
              {{ activeFiltersLabel }}
            </gl-badge>
            <gl-badge
              v-if="urlCommittedAfter"
              variant="info"
              class="gl-hidden @md/panel:gl-inline-flex"
            >
              {{ $options.i18n.committedAfter }}: {{ urlCommittedAfter }}
            </gl-badge>
            <gl-badge
              v-if="urlCommittedBefore"
              variant="info"
              class="gl-hidden @md/panel:gl-inline-flex"
            >
              {{ $options.i18n.committedBefore }}: {{ urlCommittedBefore }}
            </gl-badge>
          </span>
          <gl-icon class="gl-button-icon gl-new-dropdown-chevron" name="chevron-down" />
        </gl-button>
      </template>

      <div class="gl-flex gl-flex-col gl-gap-3 gl-p-4">
        <gl-form-group :label="$options.i18n.committedAfter" label-for="committed-after-input">
          <gl-datepicker
            input-id="committed-after-input"
            :target="null"
            :container="null"
            :value="committedAfterDate"
            show-clear-button
            data-testid="committed-after-input"
            @input="onCommittedAfterInput"
            @clear="onCommittedAfterInput(null)"
          />
        </gl-form-group>
        <gl-form-group :label="$options.i18n.committedBefore" label-for="committed-before-input">
          <gl-datepicker
            input-id="committed-before-input"
            :target="null"
            :container="null"
            :value="committedBeforeDate"
            show-clear-button
            data-testid="committed-before-input"
            @input="onCommittedBeforeInput"
            @clear="onCommittedBeforeInput(null)"
          />
        </gl-form-group>
        <div class="gl-flex gl-justify-end gl-gap-2">
          <gl-button
            v-if="hasActiveFilters"
            category="tertiary"
            data-testid="clear-date-filters"
            @click="clearFilters"
          >
            {{ $options.i18n.clear }}
          </gl-button>
          <gl-button variant="confirm" data-testid="apply-date-filters" @click="applyFilters">
            {{ $options.i18n.apply }}
          </gl-button>
        </div>
      </div>
    </gl-disclosure-dropdown>
  </div>
</template>
