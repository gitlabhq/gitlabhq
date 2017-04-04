/* global Api */

export default class ApproversSelect {
  constructor() {
    const approverSelect = document.querySelector('.js-select-user-and-group');
    const name = approverSelect.dataset.name;
    this.fieldNames = [`${name}[approver_ids]`, `${name}[approver_group_ids]`];

    this.bindEvents();
    this.addEvents();

    $('.js-select-user-and-group').select2({
      placeholder: 'Search for users or groups',
      multiple: true,
      minimumInputLength: 0,
      query: (query) => {
        const fetchGroups = this.fetchGroups(query.term);
        const fetchUsers = this.fetchUsers(query.term);
        return $.when(fetchGroups, fetchUsers).then((groups, users) => {
          const data = {
            results: groups[0].concat(users[0]),
          };
          return query.callback(data);
        });
      },
      formatResult: ApproversSelect.formatResult,
      formatSelection: ApproversSelect.formatSelection,
      dropdownCssClass: 'ajax-groups-dropdown',
    })
    .on('change', this.handleSelectChange);
  }

  bindEvents() {
    this.addApprover = this.addApprover.bind(this);
    this.handleSelectChange = this.handleSelectChange.bind(this);
    this.fetchGroups = this.fetchGroups.bind(this);
    this.fetchUsers = this.fetchUsers.bind(this);
  }

  addEvents() {
    $(document).on('click', '.js-approvers', this.addApprover);
    $(document).on('click', '.js-approver-remove', ApproversSelect.removeApprover);
  }

  static getOptions(fieldName, selector, key) {
    const input = $(`[name="${fieldName}"]`);
    const existingApprovers = [].map.call(
      document.querySelectorAll(selector),
      item => parseInt(item.getAttribute('data-id'), 10),
    );
    const selectedApprovers = input.val()
      .split(',')
      .filter(val => val !== '');
    const options = {
      [key]: [...existingApprovers, ...selectedApprovers],
    };
    return options;
  }

  fetchGroups(term) {
    const options = ApproversSelect.getOptions(this.fieldNames[1], '.js-approver-group', 'skip_groups');
    return Api.groups(term, options);
  }

  fetchUsers(term) {
    const options = ApproversSelect.getOptions(this.fieldNames[0], '.js-approver', 'skip_users');
    return Api.users(term, options);
  }

  handleSelectChange(evt) {
    const { added, removed } = evt;
    const userInput = $(`[name="${this.fieldNames[0]}"]`);
    const groupInput = $(`[name="${this.fieldNames[1]}"]`);

    if (added) {
      if (added.full_name) {
        groupInput.val(`${groupInput.val()},${added.id}`.replace(/^,/, ''));
      } else {
        userInput.val(`${userInput.val()},${added.id}`.replace(/^,/, ''));
      }
    }

    if (removed) {
      if (removed.full_name) {
        groupInput.val(groupInput.val().replace(new RegExp(`,?${removed.id}`), ''));
      } else {
        userInput.val(userInput.val().replace(new RegExp(`,?${removed.id}`), ''));
      }
    }
  }

  static formatSelection(group) {
    return group.full_name || group.name;
  }

  static formatResult({
    avatar_url: avatarUrl,
    full_name: fullName,
    full_path: fullPath,
    name,
    username,
  }) {
    if (username) {
      const avatar = avatarUrl || gon.default_avatar_url;
      return `
        <div class="user-result">
          <div class="user-image">
            <img class="avatar s24" src="${avatar}">
          </div>
          <div class="user-name">${name}</div>
          <div class="user-username">@${username}</div>
        </div>
      `;
    }

    return `
      <div class="group-result">
        <div class="group-name">${fullName}</div>
        <div class="group-path">${fullPath}</div>
      </div>
    `;
  }

  addApprover() {
    this.fieldNames.forEach(ApproversSelect.saveApprovers);
  }

  static saveApprovers(fieldName) {
    const $input = $(`[name="${fieldName}"]`);
    const newValue = $input.val();

    if (!newValue) {
      return;
    }

    const $form = $('.js-approvers').closest('form');
    $('.load-wrapper').removeClass('hidden');
    $.ajax({
      url: $form.attr('action'),
      type: 'POST',
      data: {
        _method: 'PATCH',
        [fieldName]: newValue,
      },
      success: ApproversSelect.updateApproverList,
      complete() {
        $input.val('val', '');
        $('.js-select-user-and-group').select2('val', '');
        $('.load-wrapper').addClass('hidden');
      },
      error() {
        // TODO: scroll into view or toast
        window.Flash('Failed to add Approver', 'alert');
      },
    });
  }

  static removeApprover(evt) {
    evt.preventDefault();
    const target = evt.currentTarget;
    $('.load-wrapper').removeClass('hidden');
    $.ajax({
      url: target.getAttribute('href'),
      type: 'POST',
      data: {
        _method: 'DELETE',
      },
      success: ApproversSelect.updateApproverList,
      complete: () => $('.load-wrapper').addClass('hidden'),
      error() {
        window.Flash('Failed to remove Approver', 'alert');
      },
    });
  }

  static updateApproverList(html) {
    $('.approver-list').html($(html).find('.approver-list').html());
  }
}
