/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, quotes, consistent-return, no-undef, no-new, prefer-arrow-callback, no-return-assign, one-var, one-var-declaration-per-line, object-shorthand, comma-dangle, no-else-return, newline-per-chained-call, no-shadow, semi, vars-on-top, indent, prefer-template, padded-blocks, max-len */
(function() {
  this.Project = (function() {
    function Project() {
      $('ul.clone-options-dropdown a').click(function() {
        var url;
        if ($(this).hasClass('active')) {
          return;
        }
        $('.active').not($(this)).removeClass('active');
        $(this).toggleClass('active');
        url = $("#project_clone").val();
        $('#project_clone').val(url);
        return $('.clone').text(url);
      // Git protocol switcher
      // Remove the active class for all buttons (ssh, http, kerberos if shown)
      // Add the active class for the clicked button
      // Update the input field
      // Update the command line instructions
      });
      // Ref switcher
      this.initRefSwitcher();
      $('.project-refs-select').on('change', function() {
        return $(this).parents('form').submit();
      });
      $('.hide-no-ssh-message').on('click', function(e) {
        Cookies.set('hide_no_ssh_message', 'false');
        $(this).parents('.no-ssh-key-message').remove();
        return e.preventDefault();
      });
      $('.hide-no-password-message').on('click', function(e) {
        Cookies.set('hide_no_password_message', 'false');
        $(this).parents('.no-password-message').remove();
        return e.preventDefault();
      });
      this.projectSelectDropdown();
    }

    Project.prototype.projectSelectDropdown = function() {
      new ProjectSelect();
      $('.project-item-select').on('click', (function(_this) {
        return function(e) {
          return _this.changeProject($(e.currentTarget).val());
        };
      })(this));
      return $('.js-projects-dropdown-toggle').on('click', function(e) {
        e.preventDefault();
        return $('.js-projects-dropdown').select2('open');
      });
    };

    Project.prototype.changeProject = function(url) {
      return window.location = url;
    };

    Project.prototype.initRefSwitcher = function() {
      return $('.js-project-refs-dropdown').each(function() {
        var $dropdown, selected;
        $dropdown = $(this);
        selected = $dropdown.data('selected');
        return $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: $dropdown.data('refs-url'),
              data: {
                ref: $dropdown.data('ref')
              },
              dataType: "json"
            }).done(function(refs) {
              return callback(refs);
            });
          },
          selectable: true,
          filterable: true,
          filterByText: true,
          fieldName: $dropdown.data('field-name'),
          renderRow: function(ref) {
            var link;
            if (ref.header != null) {
              return $('<li />').addClass('dropdown-header').text(ref.header);
            } else {
              link = $('<a />').attr('href', '#').addClass(ref === selected ? 'is-active' : '').text(ref).attr('data-ref', ref);
              return $('<li />').append(link);
            }
          },
          id: function(obj, $el) {
            return $el.attr('data-ref');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          },
          clicked: function(selected, $el, e) {
            e.preventDefault()
            if ($('input[name="ref"]').length) {
              var $form = $dropdown.closest('form'),
                  action = $form.attr('action'),
                  divider = action.indexOf('?') < 0 ? '?' : '&';
              Turbolinks.visit(action + '' + divider + '' + $form.serialize());
            }
          }
        });
      });
    };

    return Project;

  })();

}).call(this);
