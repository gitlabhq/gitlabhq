<script>
import { GlDisclosureDropdown, GlIcon, GlSearchBoxByType, GlSprintf } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { __, n__, s__, sprintf } from '~/locale';

export const i18n = {
  messageAdditionsDeletions: s__('Diffs|with %{additions} and %{deletions}'),
  noFilesFound: __('No files found.'),
  noFileNameAvailable: s__('Diffs|No file name available'),
  searchFiles: __('Search files'),
};

const variantCssColorMap = {
  success: 'gl-text-success',
  danger: 'gl-text-danger',
};

export default {
  i18n,
  components: {
    GlDisclosureDropdown,
    GlIcon,
    GlSearchBoxByType,
    GlSprintf,
  },
  props: {
    changed: {
      type: Number,
      required: true,
    },
    added: {
      type: Number,
      required: true,
    },
    deleted: {
      type: Number,
      required: true,
    },
    files: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    filteredFiles() {
      return this.search.length > 0
        ? fuzzaldrinPlus.filter(this.files, this.search, { key: 'name' })
        : this.files;
    },
    dropdownItems() {
      return this.filteredFiles.map((file) => {
        return {
          ...file,
          text: file.name || this.$options.i18n.noFileNameAvailable,
          iconColor: variantCssColorMap[file.iconColor],
        };
      });
    },
    messageChanged() {
      return sprintf(
        n__(
          'Diffs|Showing %{dropdownStart}%{count} changed file%{dropdownEnd}',
          'Diffs|Showing %{dropdownStart}%{count} changed files%{dropdownEnd}',
          this.changed,
        ),
        { count: this.changed },
      );
    },
  },
  methods: {
    focusInput() {
      this.$refs.search.focusInput();
    },
    focusFirstItem() {
      if (!this.filteredFiles.length) return;
      this.$el.querySelector('.gl-new-dropdown-item:first-child').focus();
    },
    additionsText(numberOfChanges = this.added) {
      return n__('Diffs|%d addition', 'Diffs|%d additions', numberOfChanges);
    },
    deletionsText(numberOfChanges = this.deleted) {
      return n__('Diffs|%d deletion', 'Diffs|%d deletions', numberOfChanges);
    },
  },
};
</script>

<template>
  <div>
    <gl-sprintf :message="messageChanged">
      <template #dropdown="{ content: dropdownText }">
        <gl-disclosure-dropdown
          :toggle-text="dropdownText"
          :items="dropdownItems"
          category="tertiary"
          variant="confirm"
          data-testid="diff-stats-dropdown"
          class="gl-align-baseline"
          toggle-class="!gl-px-0 !gl-font-bold"
          fluid-width
          @shown="focusInput"
        >
          <template #header>
            <gl-search-box-by-type
              ref="search"
              v-model.trim="search"
              :placeholder="$options.i18n.searchFiles"
              class="gl-mx-3 gl-my-4"
              @keydown.down="focusFirstItem"
            />
            <span v-if="!filteredFiles.length" class="gl-mx-3">
              {{ $options.i18n.noFilesFound }}
            </span>
          </template>
          <template #list-item="{ item }">
            <div class="gl-flex gl-items-center gl-gap-3 gl-overflow-hidden">
              <gl-icon :name="item.icon" :class="item.iconColor" class="gl-shrink-0" />
              <div class="gl-grow gl-overflow-hidden">
                <div class="gl-flex">
                  <span
                    class="gl-mr-3 gl-grow gl-font-bold"
                    :class="item.name ? 'gl-truncate' : 'gl-italic gl-text-subtle'"
                    >{{ item.text }}</span
                  >
                  <span class="gl-ml-auto gl-whitespace-nowrap" aria-hidden="true">
                    <span class="gl-text-success">+{{ item.added }}</span>
                    <span class="gl-text-danger">-{{ item.removed }}</span>
                  </span>
                  <span class="gl-sr-only"
                    >{{ additionsText(item.added) }}, {{ deletionsText(item.removed) }}</span
                  >
                </div>
                <div class="gl-overflow-hidden gl-text-ellipsis gl-text-subtle">
                  {{ item.path }}
                </div>
              </div>
            </div>
          </template>
        </gl-disclosure-dropdown>
      </template>
    </gl-sprintf>
    <span
      class="diff-stats-additions-deletions-expanded"
      data-testid="diff-stats-additions-deletions-expanded"
    >
      <gl-sprintf :message="$options.i18n.messageAdditionsDeletions">
        <template #additions>
          <span class="gl-font-bold gl-text-success">{{ additionsText() }}</span>
        </template>
        <template #deletions>
          <span class="gl-font-bold gl-text-danger">{{ deletionsText() }}</span>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>

<style scoped>
/* TODO: Use max-height prop when gitlab-ui got updated.
See https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2374 */
::v-deep .gl-new-dropdown-inner {
  max-height: 310px;
}
</style>
