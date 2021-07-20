import $ from 'jquery';
import { escape } from 'lodash';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import createFlash from '~/flash';
import { __ } from '~/locale';

function isValidProjectId(id) {
  return id > 0;
}

class SidebarMoveIssue {
  constructor(mediator, dropdownToggle, confirmButton) {
    this.mediator = mediator;

    this.$dropdownToggle = $(dropdownToggle);
    this.$confirmButton = $(confirmButton);

    this.onConfirmClickedWrapper = this.onConfirmClicked.bind(this);
  }

  init() {
    this.initDropdown();
    this.addEventListeners();
  }

  destroy() {
    this.removeEventListeners();
  }

  initDropdown() {
    initDeprecatedJQueryDropdown(this.$dropdownToggle, {
      search: {
        fields: ['name_with_namespace'],
      },
      showMenuAbove: true,
      selectable: true,
      filterable: true,
      filterRemote: true,
      multiSelect: false,
      // Keep the dropdown open after selecting an option
      shouldPropagate: false,
      data: (searchTerm, callback) => {
        this.mediator
          .fetchAutocompleteProjects(searchTerm)
          .then(callback)
          .catch(() =>
            createFlash({
              message: __('An error occurred while fetching projects autocomplete.'),
            }),
          );
      },
      renderRow: (project) => `
        <li>
          <a href="#" class="js-move-issue-dropdown-item">
            ${escape(project.name_with_namespace)}
          </a>
        </li>
      `,
      clicked: (options) => {
        const project = options.selectedObj;
        const selectedProjectId = options.isMarking ? project.id : 0;
        this.mediator.setMoveToProjectId(selectedProjectId);

        this.$confirmButton.prop('disabled', !isValidProjectId(selectedProjectId));
      },
    });
  }

  addEventListeners() {
    this.$confirmButton.on('click', this.onConfirmClickedWrapper);
  }

  removeEventListeners() {
    this.$confirmButton.off('click', this.onConfirmClickedWrapper);
  }

  onConfirmClicked() {
    if (isValidProjectId(this.mediator.store.moveToProjectId)) {
      this.$confirmButton.disable().addClass('is-loading');

      this.mediator.moveIssue().catch(() => {
        createFlash({ message: __('An error occurred while moving the issue.') });
        this.$confirmButton.enable().removeClass('is-loading');
      });
    }
  }
}

export default SidebarMoveIssue;
