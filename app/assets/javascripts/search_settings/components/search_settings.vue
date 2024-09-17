<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { escapeRegExp } from 'lodash';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import {
  EXCLUDED_NODES,
  HIDE_CLASS,
  HIGHLIGHT_CLASS,
  NONE_PADDING_CLASS,
  TYPING_DELAY,
} from '../constants';

const origExpansions = new Map();

const findSettingsSection = (sectionSelector, node) => {
  return node.parentElement.closest(sectionSelector);
};

const restoreExpansionState = ({ expandSection, collapseSection }) => {
  origExpansions.forEach((isExpanded, section) => {
    if (isExpanded) {
      expandSection(section);
    } else {
      collapseSection(section);
    }
  });

  origExpansions.clear();
};

const saveExpansionState = (sections, { isExpanded }) => {
  // If we've saved expansions before, don't override it.
  if (origExpansions.size > 0) {
    return;
  }

  sections.forEach((section) => origExpansions.set(section, isExpanded(section)));
};

const resetSections = ({ sectionSelector }) => {
  document.querySelectorAll(sectionSelector).forEach((section) => {
    section.classList.remove(HIDE_CLASS);
  });
};

const clearHighlights = () => {
  document.querySelectorAll(`.${HIGHLIGHT_CLASS}`).forEach((element) => {
    const { parentNode } = element;
    const textNode = document.createTextNode(element.textContent);
    parentNode.replaceChild(textNode, element);

    parentNode.normalize();
  });
};

const hideSectionsExcept = (sectionSelector, visibleSections) => {
  Array.from(document.querySelectorAll(sectionSelector))
    .filter((section) => !visibleSections.includes(section))
    .forEach((section) => {
      section.classList.add(HIDE_CLASS);
    });
};

const highlightTextNode = (textNode, searchTerm) => {
  const escapedSearchTerm = new RegExp(`(${escapeRegExp(searchTerm)})`, 'gi');
  const textList = textNode.data.split(escapedSearchTerm);

  return textList.reduce((documentFragment, text) => {
    let addElement;

    if (escapedSearchTerm.test(text)) {
      addElement = document.createElement('mark');
      addElement.className = `${HIGHLIGHT_CLASS} ${NONE_PADDING_CLASS}`;
      addElement.textContent = text;
      escapedSearchTerm.lastIndex = 0;
    } else {
      addElement = document.createTextNode(text);
    }

    documentFragment.appendChild(addElement);
    return documentFragment;
  }, document.createDocumentFragment());
};

const highlightText = (textNodes = [], searchTerm) => {
  textNodes.forEach((textNode) => {
    const fragmentWithHighlights = highlightTextNode(textNode, searchTerm);
    textNode.parentElement.replaceChild(fragmentWithHighlights, textNode);
  });
};

const displayResults = ({ sectionSelector, expandSection, searchTerm }, matchingTextNodes) => {
  const sections = Array.from(
    new Set(matchingTextNodes.map((node) => findSettingsSection(sectionSelector, node))),
  );

  hideSectionsExcept(sectionSelector, sections);
  sections.forEach(expandSection);
  highlightText(matchingTextNodes, searchTerm);

  return sections.length > 0;
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
  const textNodes = [];

  for (let currentNode = iterator.nextNode(); currentNode; currentNode = iterator.nextNode()) {
    textNodes.push(currentNode);
  }

  return textNodes;
};

export default {
  components: {
    EmptyResult,
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
    hideWhenEmptySelector: {
      type: String,
      required: true,
      default: null,
    },
    isExpandedFn: {
      type: Function,
      required: false,
      // default to a function that returns false
      default: () => () => false,
    },
  },
  data() {
    return {
      searchTerm: '',
      hasMatches: true,
    };
  },
  watch: {
    hasMatches(newHasMatches) {
      document.querySelectorAll(this.hideWhenEmptySelector).forEach((section) => {
        section.classList.toggle(HIDE_CLASS, !newHasMatches);
      });
    },
  },
  methods: {
    search(value) {
      this.searchTerm = value;
      const displayOptions = {
        sectionSelector: this.sectionSelector,
        expandSection: this.expandSection,
        collapseSection: this.collapseSection,
        isExpanded: this.isExpandedFn,
        searchTerm: this.searchTerm,
      };

      clearResults(displayOptions);
      this.hasMatches = true;

      if (value.length) {
        saveExpansionState(document.querySelectorAll(this.sectionSelector), displayOptions);

        this.hasMatches = displayResults(displayOptions, search(this.searchRoot, this.searchTerm));
      } else {
        restoreExpansionState(displayOptions);
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
  <div>
    <gl-search-box-by-type
      :value="searchTerm"
      :debounce="$options.TYPING_DELAY"
      :placeholder="__('Search page')"
      @input="search"
    />

    <empty-result v-if="!hasMatches" />
  </div>
</template>
