(function() {
  this.LabelsSelect = (function() {
    function LabelsSelect() {
      var _this;
      _this = this;
      $('.js-label-select').each(function(i, dropdown) {
        var $block, $colorPreview, $dropdown, $form, $loading, $selectbox, $sidebarCollapsedValue, $value, abilityName, defaultLabel, enableLabelCreateButton, issueURLSplit, issueUpdateURL, labelHTMLTemplate, labelNoneHTMLTemplate, labelUrl, projectId, saveLabelData, selectedLabel, showAny, showNo, $sidebarLabelTooltip;
        $dropdown = $(dropdown);
        projectId = $dropdown.data('project-id');
        labelUrl = $dropdown.data('labels');
        issueUpdateURL = $dropdown.data('issueUpdate');
        selectedLabel = $dropdown.data('selected');
        if ((selectedLabel != null) && !$dropdown.hasClass('js-multiselect')) {
          selectedLabel = selectedLabel.split(',');
        }
        showNo = $dropdown.data('show-no');
        showAny = $dropdown.data('show-any');
        defaultLabel = $dropdown.data('default-label');
        abilityName = $dropdown.data('ability-name');
        $selectbox = $dropdown.closest('.selectbox');
        $block = $selectbox.closest('.block');
        $form = $dropdown.closest('form');
        $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon span');
        $sidebarLabelTooltip = $block.find('.js-sidebar-labels-tooltip');
        $value = $block.find('.value');
        $loading = $block.find('.block-loading').fadeOut();
        if (issueUpdateURL != null) {
          issueURLSplit = issueUpdateURL.split('/');
        }
        if (issueUpdateURL) {
          labelHTMLTemplate = _.template('<% _.each(labels, function(label){ %> <a href="<%- ["",issueURLSplit[1], issueURLSplit[2],""].join("/") %>issues?label_name[]=<%- encodeURIComponent(label.title) %>"> <span class="label has-tooltip color-label" title="<%- label.description %>" style="background-color: <%- label.color %>; color: <%- label.text_color %>;"> <%- label.title %> </span> </a> <% }); %>');
          labelNoneHTMLTemplate = '<span class="no-value">None</span>';
        }

        $sidebarLabelTooltip.tooltip();

        if ($dropdown.closest('.dropdown').find('.dropdown-new-label').length) {
          new gl.CreateLabelDropdown($dropdown.closest('.dropdown').find('.dropdown-new-label'), projectId);
        }

        saveLabelData = function() {
          var data, selected;
          selected = $dropdown.closest('.selectbox').find("input[name='" + ($dropdown.data('field-name')) + "']").map(function() {
            return this.value;
          }).get();
          data = {};
          data[abilityName] = {};
          data[abilityName].label_ids = selected;
          if (!selected.length) {
            data[abilityName].label_ids = [''];
          }
          $loading.fadeIn();
          $dropdown.trigger('loading.gl.dropdown');
          return $.ajax({
            type: 'PUT',
            url: issueUpdateURL,
            dataType: 'JSON',
            data: data
          }).done(function(data) {
            var labelCount, template, labelTooltipTitle, labelTitles;
            $loading.fadeOut();
            $dropdown.trigger('loaded.gl.dropdown');
            $selectbox.hide();
            data.issueURLSplit = issueURLSplit;
            labelCount = 0;
            if (data.labels.length) {
              template = labelHTMLTemplate(data);
              labelCount = data.labels.length;
            } else {
              template = labelNoneHTMLTemplate;
            }
            $value.removeAttr('style').html(template);
            $sidebarCollapsedValue.text(labelCount);

            if (data.labels.length) {
              labelTitles = data.labels.map(function(label) {
                return label.title;
              });

              if (labelTitles.length > 5) {
                labelTitles = labelTitles.slice(0, 5);
                labelTitles.push('and ' + (data.labels.length - 5) + ' more');
              }

              labelTooltipTitle = labelTitles.join(', ');
            } else {
              labelTooltipTitle = '';
              $sidebarLabelTooltip.tooltip('destroy');
            }

            $sidebarLabelTooltip
              .attr('title', labelTooltipTitle)
              .tooltip('fixTitle');

            $('.has-tooltip', $value).tooltip({
              container: 'body'
            });
            return $value.find('a').each(function(i) {
              return setTimeout((function(_this) {
                return function() {
                  return gl.animate.animate($(_this), 'pulse');
                };
              })(this), 200 * i);
            });
          });
        };
        return $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: labelUrl
            }).done(function(data) {
              data = _.chain(data).groupBy(function(label) {
                return label.title;
              }).map(function(label) {
                var color;
                color = _.map(label, function(dup) {
                  return dup.color;
                });
                return {
                  id: label[0].id,
                  title: label[0].title,
                  color: color,
                  duplicate: color.length > 1
                };
              }).value();
              if ($dropdown.hasClass('js-extra-options')) {
                if (showNo) {
                  data.unshift({
                    id: 0,
                    title: 'No Label'
                  });
                }
                if (showAny) {
                  data.unshift({
                    isAny: true,
                    title: 'Any Label'
                  });
                }
                if (data.length > 2) {
                  data.splice(2, 0, 'divider');
                }
              }
              return callback(data);
            });
          },
          renderRow: function(label, instance) {
            var $a, $li, active, color, colorEl, indeterminate, removesAll, selectedClass, spacing;
            $li = $('<li>');
            $a = $('<a href="#">');
            selectedClass = [];
            removesAll = label.id === 0 || (label.id == null);
            if ($dropdown.hasClass('js-filter-bulk-update')) {
              indeterminate = instance.indeterminateIds;
              active = instance.activeIds;
              if (indeterminate.indexOf(label.id) !== -1) {
                selectedClass.push('is-indeterminate');
              }
              if (active.indexOf(label.id) !== -1) {
                i = selectedClass.indexOf('is-indeterminate');
                if (i !== -1) {
                  selectedClass.splice(i, 1);
                }
                selectedClass.push('is-active');
                instance.addInput(this.fieldName, label.id);
              }
            }
            if ($form.find("input[type='hidden'][name='" + ($dropdown.data('fieldName')) + "'][value='" + escape(this.id(label)) + "']").length) {
              selectedClass.push('is-active');
            }
            if ($dropdown.hasClass('js-multiselect') && removesAll) {
              selectedClass.push('dropdown-clear-active');
            }
            if (label.duplicate) {
              spacing = 100 / label.color.length;
              label.color = label.color.filter(function(color, i) {
                return i < 4;
              });
              color = _.map(label.color, function(color, i) {
                var percentFirst, percentSecond;
                percentFirst = Math.floor(spacing * i);
                percentSecond = Math.floor(spacing * (i + 1));
                return color + " " + percentFirst + "%," + color + " " + percentSecond + "% ";
              }).join(',');
              color = "linear-gradient(" + color + ")";
            } else {
              if (label.color != null) {
                color = label.color[0];
              }
            }
            if (color) {
              colorEl = "<span class='dropdown-label-box' style='background: " + color + "'></span>";
            } else {
              colorEl = '';
            }
            if (label.id) {
              selectedClass.push('label-item');
              $a.attr('data-label-id', label.id);
            }
            $a.addClass(selectedClass.join(' ')).html(colorEl + " " + label.title);
            return $li.html($a).prop('outerHTML');
          },
          persistWhenHide: $dropdown.data('persistWhenHide'),
          search: {
            fields: ['title']
          },
          selectable: true,
          filterable: true,
          toggleLabel: function(selected, el) {
            var selected_labels;
            selected_labels = $('.js-label-select').siblings('.dropdown-menu-labels').find('.is-active');
            if (selected && (selected.title != null)) {
              if (selected_labels.length > 1) {
                return selected.title + " +" + (selected_labels.length - 1) + " more";
              } else {
                return selected.title;
              }
            } else if (!selected && selected_labels.length !== 0) {
              if (selected_labels.length > 1) {
                return ($(selected_labels[0]).text()) + " +" + (selected_labels.length - 1) + " more";
              } else if (selected_labels.length === 1) {
                return $(selected_labels).text();
              }
            } else {
              return defaultLabel;
            }
          },
          fieldName: $dropdown.data('field-name'),
          id: function(label) {
            if ($dropdown.hasClass("js-filter-submit") && (label.isAny == null)) {
              return label.title;
            } else {
              return label.id;
            }
          },
          hidden: function() {
            var isIssueIndex, isMRIndex, page, selectedLabels;
            page = $('body').data('page');
            isIssueIndex = page === 'projects:issues:index';
            isMRIndex = page === 'projects:merge_requests:index';
            $selectbox.hide();
            $value.removeAttr('style');
            if (page === 'projects:boards:show') {
              return;
            }
            if ($dropdown.hasClass('js-multiselect')) {
              if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
                selectedLabels = $dropdown.closest('form').find("input:hidden[name='" + ($dropdown.data('fieldName')) + "']");
                Issuable.filterResults($dropdown.closest('form'));
              } else if ($dropdown.hasClass('js-filter-submit')) {
                $dropdown.closest('form').submit();
              } else {
                if (!$dropdown.hasClass('js-filter-bulk-update')) {
                  saveLabelData();
                }
              }
            }
            if ($dropdown.hasClass('js-filter-bulk-update')) {
              if (!this.options.persistWhenHide) {
                return $dropdown.parent().find('.is-active, .is-indeterminate').removeClass();
              }
            }
          },
          multiSelect: $dropdown.hasClass('js-multiselect'),
          clicked: function(label, $el, e) {
            var isIssueIndex, isMRIndex, page;
            _this.enableBulkLabelDropdown();
            if ($dropdown.hasClass('js-filter-bulk-update')) {
              return;
            }
            page = $('body').data('page');
            isIssueIndex = page === 'projects:issues:index';
            isMRIndex = page === 'projects:merge_requests:index';
            if (page === 'projects:boards:show') {
              if (label.isAny) {
                gl.issueBoards.BoardsStore.state.filters['label_name'] = [];
              } else if (label.title) {
                gl.issueBoards.BoardsStore.state.filters['label_name'].push(label.title);
              } else {
                var filters = gl.issueBoards.BoardsStore.state.filters['label_name'];
                filters = filters.filter(function (label) {
                  return label !== $el.text().trim();
                });
                gl.issueBoards.BoardsStore.state.filters['label_name'] = filters;
              }

              gl.issueBoards.BoardsStore.updateFiltersUrl();
              e.preventDefault();
              return;
            } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
              if (!$dropdown.hasClass('js-multiselect')) {
                selectedLabel = label.title;
                return Issuable.filterResults($dropdown.closest('form'));
              }
            } else if ($dropdown.hasClass('js-filter-submit')) {
              return $dropdown.closest('form').submit();
            } else {
              if ($dropdown.hasClass('js-multiselect')) {

              } else {
                return saveLabelData();
              }
            }
          },
          setIndeterminateIds: function() {
            if (this.dropdown.find('.dropdown-menu-toggle').hasClass('js-filter-bulk-update')) {
              return this.indeterminateIds = _this.getIndeterminateIds();
            }
          },
          setActiveIds: function() {
            if (this.dropdown.find('.dropdown-menu-toggle').hasClass('js-filter-bulk-update')) {
              return this.activeIds = _this.getActiveIds();
            }
          }
        });
      });
      this.bindEvents();
    }

    LabelsSelect.prototype.bindEvents = function() {
      return $('body').on('change', '.selected_issue', this.onSelectCheckboxIssue);
    };

    LabelsSelect.prototype.onSelectCheckboxIssue = function() {
      if ($('.selected_issue:checked').length) {
        return;
      }
      $('.issues_bulk_update .labels-filter input[type="hidden"]').remove();
      return $('.issues_bulk_update .labels-filter .dropdown-toggle-text').text('Label');
    };

    LabelsSelect.prototype.getIndeterminateIds = function() {
      var label_ids;
      label_ids = [];
      $('.selected_issue:checked').each(function(i, el) {
        var issue_id;
        issue_id = $(el).data('id');
        return label_ids.push($("#issue_" + issue_id).data('labels'));
      });
      return _.flatten(label_ids);
    };

    LabelsSelect.prototype.getActiveIds = function() {
      var label_ids;
      label_ids = [];
      $('.selected_issue:checked').each(function(i, el) {
        var issue_id;
        issue_id = $(el).data('id');
        return label_ids.push($("#issue_" + issue_id).data('labels'));
      });
      return _.intersection.apply(_, label_ids);
    };

    LabelsSelect.prototype.enableBulkLabelDropdown = function() {
      var issuableBulkActions;
      if ($('.selected_issue:checked').length) {
        issuableBulkActions = $('.bulk-update').data('bulkActions');
        return issuableBulkActions.willUpdateLabels = true;
      }
    };

    return LabelsSelect;

  })();

}).call(this);
