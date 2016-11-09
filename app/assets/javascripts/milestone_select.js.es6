/* eslint-disable */
(function (global) {
  class MilestoneSelect {
    constructor(currentProject) {
      this.currentProject = currentProject ? JSON.parse(currentProject) : null;
      this.dropdown = document.querySelectorAll('.js-milestone-select');
      this.dataset = this.dropdown.dataset;
      // worth checking if this is being run for each time it's called.
      const $selectbox = $dropdown.closest('.selectbox');
      const $block = $selectbox.closest('.block');
      const $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon');
      const $value = $block.find('.value');
      const $loading = $block.find('.block-loading').fadeOut();
      // either make member or lookup as needed.
      // one dom query total plus jquery plugin
      // hasClass add it to the utils
      // get rid of all the dom queries 

      let milestoneLinkTemplate;
      let milestoneLinkNoneTemplate;
      let collapsedSidebarLabelTemplate;

      
      this.initTemplates();
      this.initDropdown();
    }
    initTemplates() {
      if (this.dataset.issueUpdateURL) {
        this.tpl = {
          milestoneLinkTemplate: _.template(`
            <a href='/<%- namespace %>/ <%- path %>/milestones/<%- iid %>' class='bold has-tooltip' 
              data-container='body' title='<%- remaining %>'><%- title %>
            </a>
          `),
          milestoneLinkNoneTemplate: `<span class='no-value'>None</span>`,
          collapsedSidebarLabelTemplate: _.template(`
            <span class='has-tooltip' data-container='body' title='<%- remaining %>' 
              data-placement='left'> <%- title %> 
            </span>`
          ),
        };    
      }
    }

    initDropdown() {
      const showMenuAbove = this.dataset['showMenuAbove'];
      const fieldName = this.dataset['fieldName'];
      const selectedMilestone = this.dataset['selected'];
      const isSelected = milestone => milestone.name === selectedMilestone;
      const vue = this.dropdown.hasClass('js-issue-board-sidebar');
      const searchFields = { fields: ['title'] };
      const defaultLabel = dropdownDataset['defaultLabel'];

      $(this.dropdown).glDropdown({
        vue,
        showMenuAbove,
        defaultLabel,
        fieldName,
        isSelected,
        filterable: true,
        selectable: true,
        id: this.idFilter,
        search: searchFields,
        data: this.fetchData,
        text: this.escapeText,
        hidden: this.hideStuff,
        toggleLabel: this.toggleLabel,
        clicked: this.handleDropdownClick,
      });
    }

    hideStuff() {
      $selectbox.hide();
      // display:block overrides the hide-collapse rule
      $value.css('display', '');

    }
    
    escapeText(milestone) {
      return _.escape(milestone.title);
    }
    
    idFilter(milestone) {
      const useId = this.dataset['useId'];
      return (!useId && !$dropdown.is('.js-issuable-form-dropdown')) ? milestone.name : milestone.id;
    }
    
    fetchData(term, callback) {
      const milestonesUrl = this.dataset['milestonesUrl'];

      return $.ajax({ url: milestonesUrl })
        .done((data) => {
          const extraOptions = prepExtraOptions();
          callback(extraOptions.concat(data));
          this.positionMenuAbove();
        });
    }
    
    toggleLabel() {
      // Question: What are the main datastructures at work. How are the classes organized?
      const defaultLabel = dropdownDataset['defaultLabel'];

      return (selected, el, e) => (selected && selected.id && el.hasClass('is-active')) ? 
        selected.title : defaultLabel;
    }
    
    positionMenuAbove() {
      if (showMenuAbove) {
        this.dropdown.positionMenuAbove();
      }
    }
    
    pushExtraOptions(extraOptions, id, name, title) {
      const divider = 'divider';
      const pushable = id === divider ? divider : { id, name, title };
      extraOptions.push(pushable);
    }
    
    prepExtraOptions() {
      const showNo = this.dataset['showNo'];
      const showAny = this.dataset['showAny'];
      const showMenuAbove = this.dataset['showMenuAbove'];
      const showUpcoming = this.dataset['showUpcoming'];

      var extraOptions = [];
      if (showAny) {
        pushExtraOptions(extraOptions, 0, '', 'Any Milestone');
      }
      if (showNo) {
        pushExtraOptions(extraOptions, -1, 'No Milestone', 'No Milestone');
      }
      // DRY ME UP (these configs)
      if (showUpcoming) {
        pushExtraOptions(extraOptions, -2, '#upcoming', 'Upcoming')
      }
      if (extraOptions.length) {
        pushExtraOptions(extraOptions, 'divider');
      }
    }
    
    initLoadingUi() {
      $loading.fadeIn();
      $dropdown.trigger('loading.gl.dropdown');
    }
    // much better method name
    // adds documention to configuration
    handlePut(data) {
      $dropdown.trigger('loaded.gl.dropdown');
      $loading.fadeOut();
      $selectbox.hide();
      $value.css('display', '');
      if (data.milestone != null) {
        data.milestone.namespace = this.currentProject.namespace;
        data.milestone.path = this.currentProject.path;
        data.milestone.remaining = gl.utils.timeFor(data.milestone.due_date);
        $value.html(milestoneLinkTemplate(data.milestone));
        return $sidebarCollapsedValue.find('span').html(collapsedSidebarLabelTemplate(data.milestone));
      } else {
        $value.html(milestoneLinkNoneTemplate);
        return $sidebarCollapsedValue.find('span').text('No');
      }
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

      $dropdown.trigger('loading.gl.dropdown');
      $loading.fadeIn();

      gl.issueBoards.BoardsStore.detail.issue.update($dropdown.attr('data-issue-update'))
        .then(function () {
          $dropdown.trigger('loaded.gl.dropdown');
          $loading.fadeOut();
        });
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

    handleDropdownClick(selected, $el, e) {
      // No jq needed here.
      const page = $('body').data('page');
      const isIssueIndex = page === 'projects:issues:index';
      const isMRIndex = page === 'projects:merge_requests:index';
      const isInvalidMilestone = this.dropdown.hasClass('js-filter-bulk-update') || this.dropdown.hasClass('js-issuable-form-dropdown');

      if (isInvalidMilestone) {
        return e.preventDefault();
      }

      const isBoardPage = $('html').hasClass('issue-boards-page') && !$dropdown.hasClass('js-issue-board-sidebar');
      const isSubmittableIndex = $dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex);
      const isSubmittableNonIndex = $dropdown.hasClass('js-filter-submit');
      const isBoardSidebar = $dropdown.hasClass('js-issue-board-sidebar');
      // all reasons not to PUT ^^
      if (isBoardPage) {
        this.putIssueBoardPage();
      } else if (isSubmittableIndex) {
        this.putSubmittableIndex();
      } else if (isSubmittableNonIndex) {
        this.putSubmittableNonIndex();
      } else if (isBoardSidebar) {
        this.putIssueBoardSidebar();
      } else {
        // PUT it
        const abilityName = this.dataset['abilityName'];

        const milestone_id = $selectbox.find('input[type="hidden"]').val();
        const milestonePayload = { [abilityName]: { milestone_id } };
        // Swap out for vue resource.
        $.ajax({ type: 'PUT', url: issueUpdateURL, data: milestonePayload })
          .done(data => this.handlePut);
      }
    }
  }
  
  global.MilestoneSelect = MilestoneSelect;
})(window.gl || (window.gl = {}));
