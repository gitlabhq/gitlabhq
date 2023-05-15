<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlSprintf,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { __, n__, s__, sprintf } from '~/locale';

export const i18n = {
  messageAdditionsDeletions: s__('Diffs|with %{additions} and %{deletions}'),
  noFilesFound: __('No files found.'),
  noFileNameAvailable: s__('Diffs|No file name available'),
  searchFiles: __('Search files'),
};

export default {
  i18n,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
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

    additionsText() {
      return n__('Diffs|%d addition', 'Diffs|%d additions', this.added);
    },
    deletionsText() {
      return n__('Diffs|%d deletion', 'Diffs|%d deletions', this.deleted);
    },
  },
  methods: {
    jumpToFile(fileHash) {
      window.location.hash = fileHash;
    },
    focusInput() {
      this.$refs.search.focusInput();
    },
  },
};
</script>

<template>
  <div>
    <gl-sprintf :message="messageChanged">
      <template #dropdown="{ content: dropdownText }">
        <gl-dropdown
          category="tertiary"
          variant="confirm"
          :text="dropdownText"
          data-testid="diff-stats-dropdown"
          class="gl-vertical-align-baseline"
          toggle-class="gl-px-0! gl-font-weight-bold!"
          menu-class="gl-w-auto!"
          no-flip
          @shown="focusInput"
        >
          <template #header>
            <gl-search-box-by-type
              ref="search"
              v-model.trim="search"
              :placeholder="$options.i18n.searchFiles"
            />
          </template>
          <gl-dropdown-item
            v-for="file in filteredFiles"
            :key="file.href"
            :icon-name="file.icon"
            :icon-color="file.iconColor"
            @click="jumpToFile(file.href)"
          >
            <div class="gl-display-flex">
              <span v-if="file.name" class="gl-font-weight-bold gl-mr-3 gl-text-truncate">{{
                file.name
              }}</span>
              <span v-else class="gl-mr-3 gl-font-weight-bold gl-font-style-italic gl-gray-400">{{
                $options.i18n.noFileNameAvailable
              }}</span>
              <span class="gl-ml-auto gl-white-space-nowrap">
                <span class="gl-text-green-600">+{{ file.added }}</span>
                <span class="gl-text-red-500">-{{ file.removed }}</span>
              </span>
            </div>
            <div class="gl-text-gray-700 gl-overflow-hidden gl-text-overflow-ellipsis">
              {{ file.path }}
            </div>
          </gl-dropdown-item>
          <gl-dropdown-text v-if="!filteredFiles.length">
            {{ $options.i18n.noFilesFound }}
          </gl-dropdown-text>
        </gl-dropdown>
      </template>
    </gl-sprintf>
    <span
      class="diff-stats-additions-deletions-expanded"
      data-testid="diff-stats-additions-deletions-expanded"
    >
      <gl-sprintf :message="$options.i18n.messageAdditionsDeletions">
        <template #additions>
          <span class="gl-text-green-600 gl-font-weight-bold">{{ additionsText }}</span>
        </template>
        <template #deletions>
          <span class="gl-text-red-500 gl-font-weight-bold">{{ deletionsText }}</span>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
