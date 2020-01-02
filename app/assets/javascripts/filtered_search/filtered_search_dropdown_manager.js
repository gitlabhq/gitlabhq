import AvailableDropdownMappings from 'ee_else_ce/filtered_search/available_dropdown_mappings';
import _ from 'underscore';
import DropLab from '~/droplab/drop_lab';
import FilteredSearchContainer from './container';
import FilteredSearchTokenKeys from './filtered_search_token_keys';
import DropdownUtils from './dropdown_utils';
import FilteredSearchVisualTokens from './filtered_search_visual_tokens';
import { DROPDOWN_TYPE } from './constants';

export default class FilteredSearchDropdownManager {
  constructor({
    runnerTagsEndpoint = '',
    labelsEndpoint = '',
    milestonesEndpoint = '',
    releasesEndpoint = '',
    tokenizer,
    page,
    isGroup,
    isGroupAncestor,
    isGroupDecendent,
    filteredSearchTokenKeys,
  }) {
    const removeTrailingSlash = url => url.replace(/\/$/, '');

    this.container = FilteredSearchContainer.container;
    this.runnerTagsEndpoint = removeTrailingSlash(runnerTagsEndpoint);
    this.labelsEndpoint = removeTrailingSlash(labelsEndpoint);
    this.milestonesEndpoint = removeTrailingSlash(milestonesEndpoint);
    this.releasesEndpoint = removeTrailingSlash(releasesEndpoint);
    this.tokenizer = tokenizer;
    this.filteredSearchTokenKeys = filteredSearchTokenKeys || FilteredSearchTokenKeys;
    this.filteredSearchInput = this.container.querySelector('.filtered-search');
    this.page = page;
    this.groupsOnly = isGroup;
    this.includeAncestorGroups = isGroupAncestor;
    this.includeDescendantGroups = isGroupDecendent;

    this.setupMapping();

    this.cleanupWrapper = this.cleanup.bind(this);
    document.addEventListener('beforeunload', this.cleanupWrapper);
  }

  cleanup() {
    if (this.droplab) {
      this.droplab.destroy();
      this.droplab = null;
    }

    this.setupMapping();

    document.removeEventListener('beforeunload', this.cleanupWrapper);
  }

  setupMapping() {
    const supportedTokens = this.filteredSearchTokenKeys.getKeys();
    const availableMappings = new AvailableDropdownMappings(
      this.container,
      this.runnerTagsEndpoint,
      this.labelsEndpoint,
      this.milestonesEndpoint,
      this.releasesEndpoint,
      this.groupsOnly,
      this.includeAncestorGroups,
      this.includeDescendantGroups,
    );

    this.mapping = availableMappings.getAllowedMappings(supportedTokens);
  }

  static addWordToInput({
    tokenName,
    tokenOperator = '',
    tokenValue = '',
    clicked = false,
    options = {},
  }) {
    const { uppercaseTokenName = false, capitalizeTokenValue = false } = options;
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');
    FilteredSearchVisualTokens.addFilterVisualToken(tokenName, tokenOperator, tokenValue, {
      uppercaseTokenName,
      capitalizeTokenValue,
    });
    input.value = '';

    if (clicked) {
      FilteredSearchVisualTokens.moveInputToTheRight();
    }
  }

  updateCurrentDropdownOffset() {
    this.updateDropdownOffset(this.currentDropdown);
  }

  updateDropdownOffset(key) {
    // Always align dropdown with the input field
    let offset =
      this.filteredSearchInput.getBoundingClientRect().left -
      this.container.querySelector('.scroll-container').getBoundingClientRect().left;

    const maxInputWidth = 240;
    const currentDropdownWidth = this.mapping[key].element.clientWidth || maxInputWidth;

    // Make sure offset never exceeds the input container
    const offsetMaxWidth =
      this.container.querySelector('.scroll-container').clientWidth - currentDropdownWidth;
    if (offsetMaxWidth < offset) {
      offset = offsetMaxWidth;
    }

    this.mapping[key].reference.setOffset(offset);
  }

  load(key, firstLoad = false) {
    const mappingKey = this.mapping[key];
    const glClass = mappingKey.gl;
    const { element } = mappingKey;
    let forceShowList = false;

    if (!mappingKey.reference) {
      const defaultArguments = {
        droplab: this.droplab,
        dropdown: element,
        input: this.filteredSearchInput,
        tokenKeys: this.filteredSearchTokenKeys,
        filter: key,
      };
      const extraArguments = mappingKey.extraArguments || {};
      const glArguments = Object.assign({}, defaultArguments, extraArguments);

      // Passing glArguments to `new glClass(<arguments>)`
      mappingKey.reference = new (Function.prototype.bind.apply(glClass, [null, glArguments]))();
    }

    if (firstLoad) {
      mappingKey.reference.init();
    }

    if (
      this.currentDropdown === DROPDOWN_TYPE.hint ||
      this.currentDropdown === DROPDOWN_TYPE.operator
    ) {
      // Force the dropdown to show if it was clicked from the hint dropdown
      forceShowList = true;
    }

    this.updateDropdownOffset(key);
    mappingKey.reference.render(firstLoad, forceShowList);

    this.currentDropdown = key;
  }

  loadDropdown(dropdownName = '') {
    let firstLoad = false;

    if (!this.droplab) {
      firstLoad = true;
      this.droplab = new DropLab();
    }

    if (dropdownName === DROPDOWN_TYPE.operator) {
      this.load(dropdownName, firstLoad);
      return;
    }

    const match = this.filteredSearchTokenKeys.searchByKey(dropdownName.toLowerCase());
    const shouldOpenFilterDropdown =
      match && this.currentDropdown !== match.key && this.mapping[match.key];
    const shouldOpenHintDropdown = !match && this.currentDropdown !== DROPDOWN_TYPE.hint;

    if (shouldOpenFilterDropdown || shouldOpenHintDropdown) {
      const key = match && match.key ? match.key : DROPDOWN_TYPE.hint;

      this.load(key, firstLoad);
    }
  }

  setDropdown() {
    const query = DropdownUtils.getSearchQuery(true);
    const { lastToken, searchToken } = this.tokenizer.processTokens(
      query,
      this.filteredSearchTokenKeys.getKeys(),
    );

    if (this.currentDropdown) {
      this.updateCurrentDropdownOffset();
    }
    if (lastToken === searchToken && lastToken !== null) {
      // Token is not fully initialized yet because it has no value
      // Eg. token = 'label:'

      const split = lastToken.split(':');
      const dropdownName = _.last(split[0].split(' '));
      const possibleOperatorToken = _.last(split[1]);

      const hasOperator = FilteredSearchVisualTokens.permissibleOperatorValues.includes(
        possibleOperatorToken && possibleOperatorToken.trim(),
      );

      let dropdownToOpen = '';

      if (split.length > 1) {
        const lastOperatorToken = FilteredSearchVisualTokens.getLastTokenOperator();
        dropdownToOpen = hasOperator && lastOperatorToken ? dropdownName : DROPDOWN_TYPE.operator;
      }

      this.loadDropdown(dropdownToOpen);
    } else if (lastToken) {
      const lastOperator = FilteredSearchVisualTokens.getLastTokenOperator();
      // Token has been initialized into an object because it has a value
      this.loadDropdown(lastOperator ? lastToken.key : DROPDOWN_TYPE.operator);
    } else {
      this.loadDropdown(DROPDOWN_TYPE.hint);
    }
  }

  resetDropdowns() {
    if (!this.currentDropdown) {
      return;
    }

    // Force current dropdown to hide
    this.mapping[this.currentDropdown].reference.hideDropdown();

    // Re-Load dropdown
    this.setDropdown();

    // Reset filters for current dropdown
    this.mapping[this.currentDropdown].reference.resetFilters();

    // Reposition dropdown so that it is aligned with cursor
    this.updateDropdownOffset(this.currentDropdown);
  }

  destroyDroplab() {
    this.droplab.destroy();
  }
}
