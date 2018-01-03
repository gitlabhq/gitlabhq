import Api from '~/api';

export default class ApproversSelect {
  constructor() {
    this.$approverSelect = $('.js-select-user-and-group');
    const name = this.$approverSelect.data('name');
    this.fieldNames = [`${name}[approver_ids]`, `${name}[approver_group_ids]`];
    this.$loadWrapper = $('.load-wrapper');

    this.bindEvents();
    this.addEvents();
    this.initSelect2();
  }

  bindEvents() {
    this.handleSelectChange = this.handleSelectChange.bind(this);
    this.fetchGroups = this.fetchGroups.bind(this);
    this.fetchUsers = this.fetchUsers.bind(this);
  }

  addEvents() {
    $(document).on('click', '.js-add-approvers', () => this.addApprover());
    $(document).on('click', '.js-approver-remove', e => ApproversSelect.removeApprover(e));
  }

  static getApprovers(fieldName, approverList) {
    const input = $(`[name="${fieldName}"]`);
    const existingApprovers = $(approverList).map((i, el) =>
      parseInt($(el).data('id'), 10),
    );
    const selectedApprovers = input.val()
      .split(',')
      .filter(val => val !== '');
    return [...existingApprovers, ...selectedApprovers];
  }

  fetchGroups(term) {
    const options = {
      skip_groups: ApproversSelect.getApprovers(this.fieldNames[1], '.js-approver-group'),
    };
    return Api.groups(term, options);
  }

  fetchUsers(term) {
    const options = {
      skip_users: ApproversSelect.getApprovers(this.fieldNames[0], '.js-approver'),
      project_id: $('#project_id').val(),
    };
    return Api.approverUsers(term, options);
  }

  handleSelectChange(e) {
    const { added, removed } = e;
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

  initSelect2() {
    this.$approverSelect.select2({
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
      dropdownCss() {
        const $input = $('.js-select-user-and-group .select2-input');
        const offset = $input.offset();
        const inputRightPosition = offset.left + $input.outerWidth();
        const $dropdown = $('.select2-drop-active');

        let left = offset.left;
        if ($dropdown.outerWidth() > $input.outerWidth()) {
          left = `${inputRightPosition - $dropdown.width()}px`;
        }
        return {
          left,
          right: 'auto',
          width: 'auto',
        };
      },
    })
    .on('change', this.handleSelectChange);
  }

  static formatSelection(group) {
    return group.full_name || group.name;
  }

  static formatResult({
    name,
    username,
    avatar_url: avatarUrl,
    full_name: fullName,
    full_path: fullPath,
  }) {
    if (username) {
      const avatar = avatarUrl || gon.default_avatar_url;
      return `
        <div class="user-result">
          <div class="user-image">
            <img class="avatar s40" src="${avatar}">
          </div>
          <div class="user-info">
            <div class="user-name">${name}</div>
            <div class="user-username">@${username}</div>
          </div>
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
    const $input = window.$(`[name="${fieldName}"]`);
    const newValue = $input.val();
    const $loadWrapper = $('.load-wrapper');
    const $approverSelect = $('.js-select-user-and-group');

    if (!newValue) {
      return;
    }

    const $form = $('.js-add-approvers').closest('form');
    $loadWrapper.removeClass('hidden');
    window.$.ajax({
      url: $form.attr('action'),
      type: 'POST',
      data: {
        _method: 'PATCH',
        [fieldName]: newValue,
      },
      success: ApproversSelect.updateApproverList,
      complete() {
        $input.val('');
        $approverSelect.select2('val', '');
        $loadWrapper.addClass('hidden');
      },
      error() {
        window.Flash('Failed to add Approver', 'alert');
      },
    });
  }

  static removeApprover(e) {
    e.preventDefault();
    const target = e.currentTarget;
    const $loadWrapper = $('.load-wrapper');
    $loadWrapper.removeClass('hidden');
    $.ajax({
      url: target.getAttribute('href'),
      type: 'POST',
      data: {
        _method: 'DELETE',
      },
      success: ApproversSelect.updateApproverList,
      complete: () => $loadWrapper.addClass('hidden'),
      error() {
        window.Flash('Failed to remove Approver', 'alert');
      },
    });
  }

  static updateApproverList(html) {
    $('.js-current-approvers').html($(html).find('.js-current-approvers').html());
  }
}
