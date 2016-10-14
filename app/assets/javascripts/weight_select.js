/* eslint-disable */
(function() {
  this.WeightSelect = (function() {
    function WeightSelect() {
      $('.js-weight-select').each(function(i, dropdown) {
        var $block, $dropdown, $loading, $selectbox, $sidebarCollapsedValue, $value, abilityName, updateUrl, updateWeight;
        $dropdown = $(dropdown);
        updateUrl = $dropdown.data('issueUpdate');
        $selectbox = $dropdown.closest('.selectbox');
        $block = $selectbox.closest('.block');
        $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon span');
        $value = $block.find('.value');
        abilityName = $dropdown.data('ability-name');
        $loading = $block.find('.block-loading').fadeOut();
        updateWeight = function(selected) {
          var data;
          data = {};
          data[abilityName] = {};
          data[abilityName].weight = selected != null ? selected : null;
          $loading.fadeIn();
          $dropdown.trigger('loading.gl.dropdown');
          return $.ajax({
            type: 'PUT',
            dataType: 'json',
            url: updateUrl,
            data: data
          }).done(function(data) {
            $dropdown.trigger('loaded.gl.dropdown');
            $loading.fadeOut();
            $selectbox.hide();
            if (data.weight != null) {
              $value.html(data.weight);
            } else {
              $value.html('None');
            }
            return $sidebarCollapsedValue.html(data.weight);
          });
        };
        return $dropdown.glDropdown({
          selectable: true,
          fieldName: $dropdown.data("field-name"),
          showMenuAbove: true,
          toggleLabel: function (selected, el) {
            return $(el).data("id");
          },
          hidden: function(e) {
            $selectbox.hide();
            return $value.css('display', '');
          },
          id: function(obj, el) {
            if ($(el).data("none") == null) {
              return $(el).data("id");
            } else {
              return '';
            }
          },
          clicked: function(selected, $el, e) {
            if ($(dropdown).is(".js-filter-submit")) {
              return $(dropdown).parents('form').submit();
            } else if ($(dropdown).is('.js-issuable-form-weight')) {
              e.preventDefault();
            } else {
              selected = $dropdown.closest('.selectbox').find("input[name='" + ($dropdown.data('field-name')) + "']").val();
              return updateWeight(selected);
            }
          }
        });
      });
    }

    return WeightSelect;

  })();

}).call(this);
