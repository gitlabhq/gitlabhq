<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { uniq } from 'lodash';
import { EXCLUDED_NODES, HIDE_CLASS, HIGHLIGHT_CLASS, TYPING_DELAY } from '../constants';

const findSettingsSection = (sectionSelector, node) => {
  return node.parentElement.closest(sectionSelector);
};

const resetSections = ({ sectionSelector, expandSection, collapseSection }) => {
  document.querySelectorAll(sectionSelector).forEach((section, index) => {
    section.classList.remove(HIDE_CLASS);

    if (index === 0) {
      expandSection(section);
    } else {
      collapseSection(section);
    }
  });
};

const clearHighlights = () => {
  document
    .querySelectorAll(`.${HIGHLIGHT_CLASS}`)
    .forEach((element) => element.classList.remove(HIGHLIGHT_CLASS));
};

const hideSectionsExcept = (sectionSelector, visibleSections) => {
  Array.from(document.querySelectorAll(sectionSelector))
    .filter((section) => !visibleSections.includes(section))
    .forEach((section) => {
      section.classList.add(HIDE_CLASS);
    });
};

const highlightElements = (elements = []) => {
  elements.forEach((element) => element.classList.add(HIGHLIGHT_CLASS));
};

const displayResults = ({ sectionSelector, expandSection }, matches) => {
  const elements = matches.map((match) => match.parentElement);
  const sections = uniq(elements.map((element) => findSettingsSection(sectionSelector, element)));

  hideSectionsExcept(sectionSelector, sections);
  sections.forEach(expandSection);
  highlightElements(elements);
};

const clearResults = (params) => {
  resetSections(params);
  clearHighlights();
};

const includeNode = (node, lowerSearchTerm) =>
  node.textContent.toLowerCase().includes(lowerSearchTerm) &&
  EXCLUDED_NODES.every((excluded) => !node.parentElement.closest(excluded));

const search = (root, searchTerm) => {
  const iterator = document.createNodeIterator(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      return includeNode(node, searchTerm.toLowerCase())
        ? NodeFilter.FILTER_ACCEPT
        : NodeFilter.FILTER_REJECT;
    },
  });
  const results = [];

  for (let currentNode = iterator.nextNode(); currentNode; currentNode = iterator.nextNode()) {
    results.push(currentNode);
  }

  return results;
};

export default {
  components: {
    GlSearchBoxByType,
  },
  props: {
    searchRoot: {
      type: Element,
      required: true,
    },
    sectionSelector: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  methods: {
    search(value) {
      const displayOptions = {
        sectionSelector: this.sectionSelector,
        expandSection: this.expandSection,
        collapseSection: this.collapseSection,
      };

      this.searchTerm = value;

      clearResults(displayOptions);

      if (value.length) {
        displayResults(displayOptions, search(this.searchRoot, value));
      }
    },
    expandSection(section) {
      this.$emit('expand', section);
    },
    collapseSection(section) {
      this.$emit('collapse', section);
    },
  },
  TYPING_DELAY,
};
</script>
<template>
  <gl-search-box-by-type
    :value="searchTerm"
    :debounce="$options.TYPING_DELAY"
    :placeholder="__('Search settings')"
    @input="search"
  />
</template>
