<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { uniq, escapeRegExp } from 'lodash';
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

const transformMatchElement = (element, searchTerm) => {
  const textStr = element.textContent;
  const escapedSearchTerm = new RegExp(`(${escapeRegExp(searchTerm)})`, 'gi');

  const textList = textStr.split(escapedSearchTerm);
  const replaceFragment = document.createDocumentFragment();
  textList.forEach((text) => {
    let addElement = document.createTextNode(text);
    if (escapedSearchTerm.test(text)) {
      addElement = document.createElement('mark');
      addElement.className = `${HIGHLIGHT_CLASS} ${NONE_PADDING_CLASS}`;
      addElement.textContent = text;
      escapedSearchTerm.lastIndex = 0;
    }
    replaceFragment.appendChild(addElement);
  });

  return replaceFragment;
};

const highlightElements = (elements = [], searchTerm) => {
  elements.forEach((element) => {
    const replaceFragment = transformMatchElement(element, searchTerm);
    element.innerHTML = '';
    element.appendChild(replaceFragment);
  });
};

const displayResults = ({ sectionSelector, expandSection, searchTerm }, matches) => {
  const elements = matches.map((match) => match.parentElement);
  const sections = uniq(elements.map((element) => findSettingsSection(sectionSelector, element)));

  hideSectionsExcept(sectionSelector, sections);
  sections.forEach(expandSection);
  highlightElements(elements, searchTerm);
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
    };
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

      if (value.length) {
        saveExpansionState(document.querySelectorAll(this.sectionSelector), displayOptions);

        displayResults(displayOptions, search(this.searchRoot, this.searchTerm));
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
  <gl-search-box-by-type
    :value="searchTerm"
    :debounce="$options.TYPING_DELAY"
    :placeholder="__('Search settings')"
    @input="search"
  />
</template>
