<script>
import { GlAvatar, GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import { debounce } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { queryToObject, visitUrl } from '~/lib/utils/url_utility';
import { n__, __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

const tooltipMessage = __('Searching by both author and message is currently not supported.');

export default {
  name: 'AuthorSelect',
  components: {
    GlAvatar,
    GlCollapsibleListbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectCommitsEl: {
      type: HTMLDivElement,
      required: true,
    },
  },
  data() {
    return {
      hasSearchParam: false,
      currentAuthor: '',
      searchTerm: '',
      searching: false,
    };
  },
  computed: {
    ...mapState(['commitsPath', 'commitsAuthors']),
    dropdownText() {
      return this.currentAuthor || __('Author');
    },
    dropdownItems() {
      const commitAuthorOptions = this.commitsAuthors.map((author) => ({
        value: author.name,
        text: author.name,
        secondaryText: author.username,
        avatarUrl: author.avatar_url,
      }));
      if (this.searchTerm) return commitAuthorOptions;

      const defaultOptions = {
        text: '',
        options: [{ text: __('Any Author'), value: '' }],
        textSrOnly: true,
      };
      const authorOptionsGroup = {
        text: 'authors',
        options: commitAuthorOptions,
        textSrOnly: true,
      };
      return [defaultOptions, authorOptionsGroup];
    },
    tooltipTitle() {
      return this.hasSearchParam && tooltipMessage;
    },
    searchSummarySrText() {
      return n__('%d author', '%d authors', this.commitsAuthors.length);
    },
  },
  mounted() {
    this.fetchAuthors();
    const params = queryToObject(window.location.search);
    const { search: searchParam, author: authorParam } = params;
    const commitsSearchInput = this.projectCommitsEl.querySelector('#commits-search');

    if (authorParam) {
      commitsSearchInput.setAttribute('disabled', true);
      commitsSearchInput.dataset.toggle = 'tooltip';
      commitsSearchInput.setAttribute('title', tooltipMessage);
      this.currentAuthor = authorParam;
    }

    if (searchParam) {
      this.hasSearchParam = true;
    }

    commitsSearchInput.addEventListener(
      'keyup',
      debounce((event) => this.setSearchParam(event.target.value), 500), // keyup & time is to match effect of "filter by commit message"
    );
  },
  methods: {
    ...mapActions(['fetchAuthors']),
    selectAuthor(user) {
      // Follow up issue "Remove usage of $.fadeIn from the codebase"
      // > https://gitlab.com/gitlab-org/gitlab/-/issues/214395

      // Follow up issue "Refactor commit list to a Vue Component"
      // To resolving mixing Vue + Vanilla JS
      // > https://gitlab.com/gitlab-org/gitlab/-/issues/214010
      const commitListElement = this.projectCommitsEl.querySelector('#commits-list');

      // To mimick effect of "filter by commit message"
      commitListElement.style.opacity = 0.5;
      commitListElement.style.transition = 'opacity 200ms';

      if (!user) {
        return visitUrl(this.commitsPath);
      }

      return visitUrl(`${this.commitsPath}?author=${user}`);
    },
    searchAuthors: debounce(async function debouncedSearch() {
      this.searching = true;
      await this.fetchAuthors(this.searchTerm);
      this.searching = false;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    handleSearch(input) {
      this.searchTerm = input;
      this.searchAuthors();
    },
    setSearchParam(value) {
      this.hasSearchParam = Boolean(value);
    },
  },
};
</script>

<template>
  <div ref="listboxContainer" v-gl-tooltip :title="tooltipTitle" :disabled="!hasSearchParam">
    <gl-collapsible-listbox
      v-model="currentAuthor"
      block
      is-check-centered
      searchable
      class="gl-mt-3 sm:gl-mt-0"
      :items="dropdownItems"
      :header-text="__('Search by author')"
      :toggle-text="dropdownText"
      :search-placeholder="__('Search')"
      :searching="searching"
      :disabled="hasSearchParam"
      @search="handleSearch"
      @select="selectAuthor"
    >
      <template #search-summary-sr-only>
        {{ searchSummarySrText }}
      </template>
      <template #list-item="{ item }">
        <span class="gl-flex gl-items-center">
          <gl-avatar
            v-if="item.avatarUrl"
            class="gl-mr-3"
            :size="32"
            :entity-name="item.text"
            :src="item.avatarUrl"
            :alt="item.text"
          />
          <span class="gl-flex gl-flex-col gl-overflow-hidden gl-hyphens-auto gl-break-words">
            {{ item.text }}
            <span v-if="item.secondaryText" class="gl-text-subtle">
              {{ item.secondaryText }}
            </span>
          </span>
        </span>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
