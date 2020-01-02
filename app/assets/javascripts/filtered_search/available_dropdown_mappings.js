import DropdownHint from './dropdown_hint';
import DropdownUser from './dropdown_user';
import DropdownNonUser from './dropdown_non_user';
import DropdownEmoji from './dropdown_emoji';
import NullDropdown from './null_dropdown';
import DropdownAjaxFilter from './dropdown_ajax_filter';
import DropdownOperator from './dropdown_operator';
import DropdownUtils from './dropdown_utils';
import { mergeUrlParams } from '../lib/utils/url_utility';

export default class AvailableDropdownMappings {
  constructor(
    container,
    runnerTagsEndpoint,
    labelsEndpoint,
    milestonesEndpoint,
    releasesEndpoint,
    groupsOnly,
    includeAncestorGroups,
    includeDescendantGroups,
  ) {
    this.container = container;
    this.runnerTagsEndpoint = runnerTagsEndpoint;
    this.labelsEndpoint = labelsEndpoint;
    this.milestonesEndpoint = milestonesEndpoint;
    this.releasesEndpoint = releasesEndpoint;
    this.groupsOnly = groupsOnly;
    this.includeAncestorGroups = includeAncestorGroups;
    this.includeDescendantGroups = includeDescendantGroups;
    this.filteredSearchInput = this.container.querySelector('.filtered-search');
  }

  getAllowedMappings(supportedTokens) {
    return this.buildMappings(supportedTokens, this.getMappings());
  }

  buildMappings(supportedTokens, availableMappings) {
    const allowedMappings = {
      hint: {
        reference: null,
        gl: DropdownHint,
        element: this.container.querySelector('#js-dropdown-hint'),
      },
      operator: {
        reference: null,
        gl: DropdownOperator,
        element: this.container.querySelector('#js-dropdown-operator'),
      },
    };

    supportedTokens.forEach(type => {
      if (availableMappings[type]) {
        allowedMappings[type] = availableMappings[type];
      }
    });

    return allowedMappings;
  }

  getMappings() {
    return {
      author: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-author'),
      },
      assignee: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-assignee'),
      },
      milestone: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getMilestoneEndpoint(),
          symbol: '%',
        },
        element: this.container.querySelector('#js-dropdown-milestone'),
      },
      release: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getReleasesEndpoint(),
          symbol: '',

          // The DropdownNonUser class is hardcoded to look for and display a
          // "title" property, so we need to add this property to each release object
          preprocessing: releases => releases.map(r => ({ ...r, title: r.tag })),
        },
        element: this.container.querySelector('#js-dropdown-release'),
      },
      label: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getLabelsEndpoint(),
          symbol: '~',
          preprocessing: DropdownUtils.duplicateLabelPreprocessing,
        },
        element: this.container.querySelector('#js-dropdown-label'),
      },
      'my-reaction': {
        reference: null,
        gl: DropdownEmoji,
        element: this.container.querySelector('#js-dropdown-my-reaction'),
      },
      wip: {
        reference: null,
        gl: DropdownNonUser,
        element: this.container.querySelector('#js-dropdown-wip'),
      },
      confidential: {
        reference: null,
        gl: DropdownNonUser,
        element: this.container.querySelector('#js-dropdown-confidential'),
      },
      status: {
        reference: null,
        gl: NullDropdown,
        element: this.container.querySelector('#js-dropdown-admin-runner-status'),
      },
      type: {
        reference: null,
        gl: NullDropdown,
        element: this.container.querySelector('#js-dropdown-admin-runner-type'),
      },
      tag: {
        reference: null,
        gl: DropdownAjaxFilter,
        extraArguments: {
          endpoint: this.getRunnerTagsEndpoint(),
          symbol: '~',
        },
        element: this.container.querySelector('#js-dropdown-runner-tag'),
      },
      'target-branch': {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getMergeRequestTargetBranchesEndpoint(),
          symbol: '',
        },
        element: this.container.querySelector('#js-dropdown-target-branch'),
      },
    };
  }

  getMilestoneEndpoint() {
    return `${this.milestonesEndpoint}.json`;
  }

  getReleasesEndpoint() {
    return `${this.releasesEndpoint}.json`;
  }

  getLabelsEndpoint() {
    let endpoint = `${this.labelsEndpoint}.json?`;

    if (this.groupsOnly) {
      endpoint = `${endpoint}only_group_labels=true&`;
    }

    if (this.includeAncestorGroups) {
      endpoint = `${endpoint}include_ancestor_groups=true&`;
    }

    if (this.includeDescendantGroups) {
      endpoint = `${endpoint}include_descendant_groups=true`;
    }

    return endpoint;
  }

  getRunnerTagsEndpoint() {
    return `${this.runnerTagsEndpoint}.json`;
  }

  getMergeRequestTargetBranchesEndpoint() {
    const endpoint = `${gon.relative_url_root ||
      ''}/autocomplete/merge_request_target_branches.json`;

    const params = {
      group_id: this.getGroupId(),
      project_id: this.getProjectId(),
    };

    return mergeUrlParams(params, endpoint);
  }

  getGroupId() {
    return this.filteredSearchInput.getAttribute('data-group-id') || '';
  }

  getProjectId() {
    return this.filteredSearchInput.getAttribute('data-project-id') || '';
  }
}
