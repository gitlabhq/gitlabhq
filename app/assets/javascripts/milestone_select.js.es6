/* eslint-disable */
(function (global) {
  class MilestoneSelect {
    constructor(currentProject) {
      this.$el = {};
      this.state = {};
      this.templates = {};
      this.config = {};

      this.storeDomRefs();
      this.initConfig();
      this.storePageContext();
      this.initTemplates();
      this.initDropdown();
    }

    storeDomRefs() {
      const $document = $(document);
      const $body = $document.find('body');
      const $dropdown = $document.find('.js-milestone-select');
      const $selectbox = $dropdown.closest('.selectbox');
      const $block = $selectbox.closest('.block');
      const $value = $block.find('.value');
      const $loading = $block.find('.block-loading');
      const $collapsedValue = $block.find('.sidebar-collapsed-icon');

      _.extend(this.$el, {
        body: $body,
        document: $document,
        dropdown: $dropdown,
        dropdownSelectBox: $selectbox,
        containerBlock: $block,
        valueDisplay: $value
        loadingDisplay: $loading,
        collapsedValue: $collapsedValue
      });
    }

    storePageContext() {
      const $dropdown = this.$el.dropdown;
      const currentPage = this.$el.body.data('page');

      this.config.page = {
        isIssueIndex: currentPage === 'projects:issues:index',
        isMRIndex: currentPage === 'projects:merge_requests:index',
        isBoardSidebar:  $dropdown.hasClass('js-issue-board-sidebar'),
        isSubmittableNonIndex: $dropdown.hasClass('js-filter-submit'),
        isSubmittableIndex:  $dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex),
        isBoardIndex:  $('html').hasClass('issue-boards-page') && !$dropdown.hasClass('js-issue-board-sidebar'),
        isInvalidMilestone:  this.dropdown.hasClass('js-filter-bulk-update') || this.dropdown.hasClass('js-issuable-form-dropdown'),
      };

      const dataset = this.config.dataset = this.$el.dropdown.dataset;

      this.config.display = {
        showMenuAbove: dataset['showMenuAbove'],
        showNo: dataset['showNo'],
        showAny: dataset['showAny'],
        showUpcoming: dataset['showUpcoming'],
        extraOptions: []
      };
    }

    initState() {
      this.state.currentProject = currentProject ? JSON.parse(currentProject) : null;
    }

    initTemplates() {
      if (this.dataset.issueUpdateURL) {
        this.templates = {
          milestoneLink: _.template(`
            <a href='/<%- namespace %>/ <%- path %>/milestones/<%- iid %>' class='bold has-tooltip'
              data-container='body' title='<%- remaining %>'><%- title %>
            </a>
          `),
          milestoneLinkNone: `<span class='no-value'>None</span>`,
          collapsedSidebarLabel: _.template(`
            <span class='has-tooltip' data-container='body' title='<%- remaining %>'
              data-placement='left'> <%- title %>
            </span>`
          ),
        };
      }
    }

    initDropdown() {
      const dataset = this.config.dataset;
      const selectedMilestone = dataset['selected'];
      const searchFields = { fields: ['title'] };
      const isSelected = milestone => milestone.name === selectedMilestone;

      $(this.dropdown).glDropdown({
        isSelected,
        filterable: true,
        selectable: true,
        search: searchFields,
        defaultLabel: dataset.defaultLabel,
        fieldName: dataset.fieldName,
        vue: this.config.page.isBoardSidebar,
        showMenuAbove: this.config.display.showMenuAbove,
        id: this.filterSelected,
        data: this.fetchMilestones,
        text: this.escapeText,
        hidden: this.renderDisplayState,
        toggleLabel: this.toggleLabel,
        clicked: this.handleDropdownClick,
      });
    }

    renderDisplayState() {
      $selectbox.hide();
      // display:block overrides the hide-collapse rule
      $value.css('display', '');

    }

    escapeText(milestone) {
      return _.escape(milestone.title);
    }

    filterSelected(milestone) {
      const useId = this.dataset['useId'];
      return (!useId && !this.$el.dropdown.is('.js-issuable-form-dropdown')) ? milestone.name : milestone.id;
    }

    fetchMilestones(term, callback) {
      const milestonesUrl = this.dataset['milestonesUrl'];

      return $.ajax({ url: milestonesUrl })
        .done((data) => {
          this.prepExtraOptions();
          callback(this.config.extraOptions.concat(data));
          this.positionMenuAbove();
        });
    }

    toggleLabel() {
      const defaultLabel = dropdownDataset['defaultLabel'];

      return (selected, el, e) => (selected && selected.id && el.hasClass('is-active')) ?
        selected.title : defaultLabel;
    }

    positionMenuAbove() {
      if (this.config.display.showMenuAbove) {
        this.$el.dropdown.positionMenuAbove();
      }
    }

    prepExtraOptions() {
      if (showAny) this.storeExtraDropdownOptions(0, '', 'Any Milestone');
      if (showNo) this.storeExtraDropdownOptions(-1, 'No Milestone', 'No Milestone');
      if (showUpcoming) this.storeExtraDropdownOptions(-2, '#upcoming', 'Upcoming');
      if (extraOptions.length) this.storeExtraDropdownOptions('divider');
    }

    storeExtraDropdownOptions(id, name, title) {
      const divider = 'divider';
      const pushable = id === divider ? divider : { id, name, title };
      this.extraOptions.push(pushable);
    }

    renderLoadingState() {
      this.$el.loadingDisplay.fadeIn();
      $dropdown.trigger('loading.gl.dropdown');
    }

    renderLoadedState() {
      this.$el.loadingDisplay.fadeOut();
      $dropdown.trigger('loaded.gl.dropdown');
    }

    handleDropdownClick(selected, $el, e) {
      const pageConfig = this.config.page;

      if (pageConfig.isInvalidMilestone) {
        return e.preventDefault();
      }

      if (pageConfig.isBoardPage) {
        return this.putIssueBoardPage();
      }

      if (pageConfig.isSubmittableIndex) {
        return this.putSubmittableIndex();
      }

      if (pageConfig.isSubmittableNonIndex) {
        return this.putSubmittableNonIndex();
      }

      if (pageConfig.isBoardSidebar) {
        return this.putIssueBoardSidebar();
      }

      return this.putGeneric();
    }

    putGeneric() {
      const abilityName = this.config.dataset['abilityName'];
      const milestone_id = this.$el.dropdownSelectBox.find('input[type="hidden"]').val();
      const milestonePayload = { [abilityName]: { milestone_id } };
      // Swap out for vue resource.
      $.ajax({ type: 'PUT', url: issueUpdateURL, data: milestonePayload })
        .done(data => this.handlePut);
    }

    putIssueBoardPage() {
      gl.issueBoards.BoardsStore.state.filters[this.dataset['fieldName']] = selected.name;
      gl.issueBoards.BoardsStore.updateFiltersUrl();
      e.preventDefault();
    }

    putIssueBoardSidebar() {
      if (selected.id !== -1) {
        Vue.set(gl.issueBoards.BoardsStore.detail.issue, 'milestone', new ListMilestone({
          id: selected.id,
          title: selected.name
        }));
      } else {
        Vue.delete(gl.issueBoards.BoardsStore.detail.issue, 'milestone');
      }

      this.renderLoadingState();

      gl.issueBoards.BoardsStore.detail.issue.update(this.config.dataset('issueUpdate'))
        .then(() =>  this.renderLoadedState());
    }

    putSubmittableIndex() {
      const selectedMilestone = this.dataset['selected'];
      // Pay attention here... looks like this is mutating selected milestone
      selectedMilestone = selected.name ? select.name : '';
      return Issuable.filterResults($dropdown.closest('form'));
    }

    putSubmittableNonIndex() {
      return $dropdown.closest('form').submit();
    }

    handlePutSuccess(data) {
      this.renderLoadedState();
      this.$el.dropdownSelectBox.hide();
      this.$el.selectedMilestone.css('display', '');

      const newMilestone = this.parsePutValue();
      this.writePutValue(newMilestone);
    }

    parsePutValue() {
      if (data.milestone != null) {
        data.milestone.namespace = this.currentProject.namespace;
        data.milestone.path = this.currentProject.path;
        data.milestone.remaining = gl.utils.timeFor(data.milestone.due_date);
      }
      return data.milestone;
    }

    writePutValue(newMilestone) {
      const $valueDisplay = this.$el.valueDisplay;
      const $collapsedValue = this.$el.collapsedValue;

      if (newMilestone != null) {
        $valueDisplay.html(this.templates.milestoneLink(data.milestone));
        $sidebarCollapsedValue.find('span').html(this.templates.collapsedSidebarLabel(data.milestone));
       } else {
        $valueDisplay.html(this.templates.milestoneLinkNone);
        $sidebarCollapsedValue.find('span').text('No');
      }
    }
  }
  global.MilestoneSelect = MilestoneSelect;
})(window.gl || (window.gl = {}));
