import { find } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { initToggle } from '~/toggles';
import {
  REPOSITORY_SETTINGS_LABEL,
  CHANGED_ALLOWED_TO_MERGE,
  CHANGED_ALLOWED_TO_PUSH_AND_MERGE,
  CHANGED_ALLOW_FORCE_PUSH,
  CHANGED_REQUIRE_CODEOWNER_APPROVAL,
} from 'ee_else_ce/projects/settings/branch_rules/tracking/constants';
import { InternalEvents } from '~/tracking';
import { initAccessDropdown } from '~/projects/settings/init_access_dropdown';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

const isDropdownDisabled = (dropdown) => {
  return dropdown?.$options.disabled === '';
};

export default class ProtectedBranchEdit {
  constructor(options) {
    this.hasLicense = options.hasLicense;
    this.sectionSelector = options.sectionSelector;
    this.hasChanges = false;
    this.$wrap = options.$wrap;

    this.selectedItems = {
      [ACCESS_LEVELS.PUSH]: [],
      [ACCESS_LEVELS.MERGE]: [],
    };
    this.initDropdowns();

    this.initToggles();
  }

  initToggles() {
    const wrap = this.$wrap.get(0);

    const forcePushToggle = initToggle(wrap.querySelector('.js-force-push-toggle'));
    if (forcePushToggle) {
      forcePushToggle.$on('change', (value) => {
        forcePushToggle.isLoading = true;
        forcePushToggle.disabled = true;
        this.updateProtectedBranch(
          {
            allow_force_push: value,
          },
          () => {
            InternalEvents.trackEvent(CHANGED_ALLOW_FORCE_PUSH, {
              label: REPOSITORY_SETTINGS_LABEL,
            });
            forcePushToggle.isLoading = false;
            forcePushToggle.disabled = false;
          },
        );
      });
    }

    if (this.hasLicense) {
      const codeOwnerToggle = initToggle(wrap.querySelector('.js-code-owner-toggle'));
      if (codeOwnerToggle) {
        codeOwnerToggle.$on('change', (value) => {
          codeOwnerToggle.isLoading = true;
          codeOwnerToggle.disabled = true;
          this.updateProtectedBranch(
            {
              code_owner_approval_required: value,
            },
            () => {
              InternalEvents.trackEvent(CHANGED_REQUIRE_CODEOWNER_APPROVAL, {
                label: REPOSITORY_SETTINGS_LABEL,
              });
              codeOwnerToggle.isLoading = false;
              codeOwnerToggle.disabled = false;
            },
          );
        });
      }
    }
  }

  initDropdowns() {
    // Allowed to Merge dropdown
    this[`${ACCESS_LEVELS.MERGE}_dropdown`] = this.buildDropdown(
      'js-allowed-to-merge',
      ACCESS_LEVELS.MERGE,
      gon.merge_access_levels,
      'protected-branch-allowed-to-merge',
      CHANGED_ALLOWED_TO_MERGE,
    );

    // Allowed to Push dropdown
    this[`${ACCESS_LEVELS.PUSH}_dropdown`] = this.buildDropdown(
      'js-allowed-to-push',
      ACCESS_LEVELS.PUSH,
      gon.push_access_levels,
      'protected-branch-allowed-to-push',
      CHANGED_ALLOWED_TO_PUSH_AND_MERGE,
    );
  }

  // eslint-disable-next-line max-params
  buildDropdown(selector, accessLevel, accessLevelsData, testId, trackingEventName) {
    const [el] = this.$wrap.find(`.${selector}`);
    if (!el) return undefined;

    const projectId = gon.current_project_id;
    const dropdown = initAccessDropdown(el, {
      toggleClass: selector,
      hasLicense: this.hasLicense,
      searchEnabled: el.dataset.filter !== undefined,
      showUsers: projectId !== undefined,
      block: true,
      accessLevel,
      accessLevelsData,
      groupsWithProjectAccess: true,
      testId,
      sectionSelector: this.sectionSelector,
    });

    dropdown.$on('select', (selected) => this.onSelectItems(accessLevel, selected));
    dropdown.$on('hidden', () => this.onDropdownHide(trackingEventName));

    this.initSelectedItems(dropdown, accessLevel);
    return dropdown;
  }

  initSelectedItems(dropdown, accessLevel) {
    if (isDropdownDisabled(dropdown)) {
      return;
    }
    this.selectedItems[accessLevel] = dropdown.preselected.map((item) => {
      if (item.type === LEVEL_TYPES.USER) return { id: item.id, user_id: item.user_id };
      if (item.type === LEVEL_TYPES.ROLE) return { id: item.id, access_level: item.access_level };
      if (item.type === LEVEL_TYPES.GROUP) return { id: item.id, group_id: item.group_id };
      return { id: item.id, deploy_key_id: item.deploy_key_id };
    });
  }

  onSelectItems(accessLevel, selected) {
    this.selectedItems[accessLevel] = selected;
    this.hasChanges = true;
  }

  onDropdownHide(trackingEventName) {
    if (!this.hasChanges) return;
    this.updatePermissions(trackingEventName);
  }

  updateProtectedBranch(formData, callback) {
    axios
      .patch(this.$wrap.data('url'), {
        protected_branch: formData,
      })
      .then(callback)
      .catch(() => {
        createAlert({ message: __('Failed to update branch!') });
      });
  }

  updatePermissions(trackingEventName) {
    const formData = Object.values(ACCESS_LEVELS).reduce((acc, level) => {
      acc[`${level}_attributes`] = this.selectedItems[level];
      return acc;
    }, {});
    this.updateProtectedBranch(formData, ({ data }) => {
      this.hasChanges = false;
      InternalEvents.trackEvent(trackingEventName, {
        label: REPOSITORY_SETTINGS_LABEL,
      });
      Object.values(ACCESS_LEVELS).forEach((level) => {
        this.setSelectedItemsToDropdown(data[level], level);
      });
    });
  }

  setSelectedItemsToDropdown(items = [], accessLevel) {
    const itemsToAdd = items.map((currentItem) => {
      if (currentItem.user_id) {
        // Do this only for users for now
        // get the current data for selected items
        const selectedItems = this.selectedItems[accessLevel];
        const currentSelectedItem = find(selectedItems, {
          user_id: currentItem.user_id,
        });

        return {
          id: currentItem.id,
          user_id: currentItem.user_id,
          type: LEVEL_TYPES.USER,
          persisted: true,
          name: currentSelectedItem.name,
          username: currentSelectedItem.username,
          avatar_url: currentSelectedItem.avatar_url,
        };
      }
      if (currentItem.group_id) {
        return {
          id: currentItem.id,
          group_id: currentItem.group_id,
          type: LEVEL_TYPES.GROUP,
          persisted: true,
        };
      }
      if (currentItem.deploy_key_id) {
        return {
          id: currentItem.id,
          deploy_key_id: currentItem.deploy_key_id,
          type: LEVEL_TYPES.DEPLOY_KEY,
          persisted: true,
        };
      }

      return {
        id: currentItem.id,
        access_level: currentItem.access_level,
        type: LEVEL_TYPES.ROLE,
        persisted: true,
      };
    });

    const dropdown = this[`${accessLevel}_dropdown`];
    if (!isDropdownDisabled(dropdown)) {
      this.selectedItems[accessLevel] = itemsToAdd;
      dropdown?.setPreselectedItems(itemsToAdd);
    }
  }
}
