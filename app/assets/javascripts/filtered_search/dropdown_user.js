import { addClassIfElementExists } from '../lib/utils/dom_utils';
import DropdownAjaxFilter from './dropdown_ajax_filter';

export default class DropdownUser extends DropdownAjaxFilter {
  constructor(options = {}) {
    super({
      ...options,
      endpoint: '/autocomplete/users.json',
      symbol: '@',
    });
  }

  ajaxFilterConfig() {
    return {
      ...super.ajaxFilterConfig(),
      params: {
        active: true,
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
    return this.input.getAttribute('data-group-id');
  }

  getProjectId() {
    return this.input.getAttribute('data-project-id');
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
