import { ACTIVE_AND_BLOCKED_USER_STATES } from '~/users_select/constants';
import { addClassIfElementExists } from '../lib/utils/dom_utils';
import DropdownAjaxFilter from './dropdown_ajax_filter';

export default class DropdownUser extends DropdownAjaxFilter {
  constructor(options = {}) {
    super({
      ...options,
      endpoint: `${gon.relative_url_root || ''}/-/autocomplete/users.json`,
      symbol: '@',
    });
  }

  ajaxFilterConfig() {
    return {
      ...super.ajaxFilterConfig(),
      params: {
        states: ACTIVE_AND_BLOCKED_USER_STATES,
        group_id: this.getGroupId(),
        project_id: this.getProjectId(),
        current_user: true,
        ...this.projectOrGroupId(),
      },
      onLoadingFinished: () => {
        this.hideCurrentUser();
      },
    };
  }

  hideCurrentUser() {
    addClassIfElementExists(this.dropdown.querySelector('.js-current-user'), 'hidden');
  }

  getGroupId() {
    return this.input.dataset.groupId;
  }

  getProjectId() {
    return this.input.dataset.projectId;
  }

  projectOrGroupId() {
    const projectId = this.getProjectId();
    const groupId = this.getGroupId();
    if (groupId) {
      return {
        group_id: groupId,
      };
    }
    return {
      project_id: projectId,
    };
  }
}
