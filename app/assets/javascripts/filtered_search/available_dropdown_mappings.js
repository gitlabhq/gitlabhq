import { sortMilestonesByDueDate } from '~/milestones/utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import {
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_TARGET_BRANCH,
  TOKEN_TYPE_SOURCE_BRANCH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import DropdownEmoji from './dropdown_emoji';
import DropdownHint from './dropdown_hint';
import DropdownNonUser from './dropdown_non_user';
import DropdownOperator from './dropdown_operator';
import DropdownUser from './dropdown_user';
import DropdownUtils from './dropdown_utils';

export default class AvailableDropdownMappings {
  constructor({
    container,
    labelsEndpoint,
    milestonesEndpoint,
    releasesEndpoint,
    environmentsEndpoint,
    groupsOnly,
    includeAncestorGroups,
    includeDescendantGroups,
  }) {
    this.container = container;
    this.labelsEndpoint = labelsEndpoint;
    this.milestonesEndpoint = milestonesEndpoint;
    this.releasesEndpoint = releasesEndpoint;
    this.environmentsEndpoint = environmentsEndpoint;
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

    supportedTokens.forEach((type) => {
      if (availableMappings[type]) {
        allowedMappings[type] = availableMappings[type];
      }
    });

    return allowedMappings;
  }

  getMappings() {
    return {
      [TOKEN_TYPE_AUTHOR]: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-author'),
      },
      [TOKEN_TYPE_ASSIGNEE]: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-assignee'),
      },
      [TOKEN_TYPE_REVIEWER]: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-reviewer'),
      },
      [TOKEN_TYPE_MERGE_USER]: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-merge-user'),
      },
      attention: {
        reference: null,
        gl: DropdownUser,
        element: this.container.getElementById('js-dropdown-attention-requested'),
      },
      [TOKEN_TYPE_APPROVED_BY]: {
        reference: null,
        gl: DropdownUser,
        element: this.container.querySelector('#js-dropdown-approved-by'),
      },
      [TOKEN_TYPE_MILESTONE]: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getMilestoneEndpoint(),
          symbol: '%',
          preprocessing: (milestones) => milestones.sort(sortMilestonesByDueDate),
        },
        element: this.container.querySelector('#js-dropdown-milestone'),
      },
      [TOKEN_TYPE_RELEASE]: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getReleasesEndpoint(),
          symbol: '',

          // The DropdownNonUser class is hardcoded to look for and display a
          // "title" property, so we need to add this property to each release object
          preprocessing: (releases) => releases.map((r) => ({ ...r, title: r.tag })),
        },
        element: this.container.querySelector('#js-dropdown-release'),
      },
      [TOKEN_TYPE_LABEL]: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getLabelsEndpoint(),
          symbol: '~',
          preprocessing: DropdownUtils.duplicateLabelPreprocessing,
        },
        element: this.container.querySelector('#js-dropdown-label'),
      },
      [TOKEN_TYPE_MY_REACTION]: {
        reference: null,
        gl: DropdownEmoji,
        element: this.container.querySelector('#js-dropdown-my-reaction'),
      },
      draft: {
        reference: null,
        gl: DropdownNonUser,
        element: this.container.querySelector('#js-dropdown-wip'),
      },
      approved: {
        reference: null,
        gl: DropdownNonUser,
        element: this.container.querySelector('#js-dropdown-approved'),
      },
      [TOKEN_TYPE_CONFIDENTIAL]: {
        reference: null,
        gl: DropdownNonUser,
        element: this.container.querySelector('#js-dropdown-confidential'),
      },
      [TOKEN_TYPE_TARGET_BRANCH]: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getMergeRequestTargetBranchesEndpoint(),
          symbol: '',
        },
        element: this.container.querySelector('#js-dropdown-target-branch'),
      },
      [TOKEN_TYPE_SOURCE_BRANCH]: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getMergeRequestSourceBranchesEndpoint(),
          symbol: '',
        },
        element: this.container.querySelector('#js-dropdown-source-branch'),
      },
      environment: {
        reference: null,
        gl: DropdownNonUser,
        extraArguments: {
          endpoint: this.getEnvironmentsEndpoint(),
          symbol: '',
          preprocessing: (data) => data.map((env) => ({ title: env })),
        },
        element: this.container.querySelector('#js-dropdown-environment'),
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

  getMergeRequestTargetBranchesEndpoint() {
    const targetBranchEndpointPath = '/-/autocomplete/merge_request_target_branches.json';
    return this.getMergeRequestBranchesEndpoint(targetBranchEndpointPath);
  }

  getMergeRequestSourceBranchesEndpoint() {
    const sourceBranchEndpointPath = '/-/autocomplete/merge_request_source_branches.json';
    return this.getMergeRequestBranchesEndpoint(sourceBranchEndpointPath);
  }

  getMergeRequestBranchesEndpoint(endpointPath = '') {
    const endpoint = `${gon.relative_url_root || ''}${endpointPath}`;
    const params = {
      group_id: this.getGroupId(),
      project_id: this.getProjectId(),
    };

    return mergeUrlParams(params, endpoint);
  }

  getEnvironmentsEndpoint() {
    return `${this.environmentsEndpoint}.json`;
  }

  getGroupId() {
    return this.filteredSearchInput.dataset.groupId || '';
  }

  getProjectId() {
    return this.filteredSearchInput.dataset.projectId || '';
  }
}
