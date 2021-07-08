<script>
import {
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlSearchBoxByType,
  GlDropdownDivider,
  GlTooltipDirective,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { redirectTo, queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

const tooltipMessage = __('Searching by both author and message is currently not supported.');

export default {
  name: 'AuthorSelect',
  components: {
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlSearchBoxByType,
    GlDropdownDivider,
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
      searchTerm: '',
      authorInput: '',
      currentAuthor: '',
    };
  },
  computed: {
    ...mapState(['commitsPath', 'commitsAuthors']),
    dropdownText() {
      return this.currentAuthor || __('Author');
    },
    tooltipTitle() {
      return this.hasSearchParam && tooltipMessage;
    },
  },
  mounted() {
    this.fetchAuthors();
    const params = queryToObject(window.location.search);
    const { search: searchParam, author: authorParam } = params;
    const commitsSearchInput = this.projectCommitsEl.querySelector('#commits-search');

    if (authorParam) {
      commitsSearchInput.setAttribute('disabled', true);
      commitsSearchInput.setAttribute('data-toggle', 'tooltip');
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
    selectAuthor(author) {
      const { name: user } = author || {};

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
        return redirectTo(this.commitsPath);
      }

      return redirectTo(`${this.commitsPath}?author=${user}`);
    },
    searchAuthors() {
      this.fetchAuthors(this.authorInput);
    },
    setSearchParam(value) {
      this.hasSearchParam = Boolean(value);
    },
  },
};
</script>

<template>
  <div ref="dropdownContainer" v-gl-tooltip :title="tooltipTitle" :disabled="!hasSearchParam">
    <gl-dropdown
      :text="dropdownText"
      :disabled="hasSearchParam"
      toggle-class="gl-py-3 gl-border-0"
      class="w-100 mt-2 mt-sm-0"
    >
      <gl-dropdown-section-header>
        {{ __('Search by author') }}
      </gl-dropdown-section-header>
      <gl-dropdown-divider />
      <gl-search-box-by-type
        v-model.trim="authorInput"
        :placeholder="__('Search')"
        @input="searchAuthors"
      />
      <gl-dropdown-item :is-checked="!currentAuthor" @click="selectAuthor(null)">
        {{ __('Any Author') }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
      <gl-dropdown-item
        v-for="author in commitsAuthors"
        :key="author.id"
        :is-checked="author.name === currentAuthor"
        :avatar-url="author.avatar_url"
        :secondary-text="author.username"
        @click="selectAuthor(author)"
      >
        {{ author.name }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
