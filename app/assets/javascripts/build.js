(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Build = (function() {
    Build.interval = null;

    Build.state = null;

    function Build(page_url, build_url, build_status, build_stage, build_name, state1) {
      this.page_url = page_url;
      this.build_url = build_url;
      this.build_status = build_status;
      this.state = state1;
      this.hideSidebar = bind(this.hideSidebar, this);
      this.toggleSidebar = bind(this.toggleSidebar, this);
      this.updateDropdown = bind(this.updateDropdown, this);
      clearInterval(Build.interval);
      this.bp = Breakpoints.get();
      $('.js-build-sidebar').niceScroll();

      this.populateJobDropdown(build_stage);
      this.updateStageDropdownText(build_stage);
      this.updateJobDropdownText(build_name);
      this.hideSidebar();

      $(document).off('click', '.js-sidebar-build-toggle').on('click', '.js-sidebar-build-toggle', this.toggleSidebar);
      $(window).off('resize.build').on('resize.build', this.hideSidebar);
      $(document).on('click', '.stage-item', this.updateDropdown);
      this.updateArtifactRemoveDate();
      if ($('#build-trace').length) {
        this.getInitialBuildTrace();
        this.initScrollButtonAffix();
      }
      if (this.build_status === "running" || this.build_status === "pending") {
        $('#autoscroll-button').on('click', function() {
          var state;
          state = $(this).data("state");
          if ("enabled" === state) {
            $(this).data("state", "disabled");
            return $(this).text("enable autoscroll");
          } else {
            $(this).data("state", "enabled");
            return $(this).text("disable autoscroll");
          }
        });
        Build.interval = setInterval((function(_this) {
          return function() {
            if (window.location.href.split("#").first() === _this.page_url) {
              return _this.getBuildTrace();
            }
          };
        })(this), 4000);
      }
    }

    Build.prototype.getInitialBuildTrace = function() {
      return $.ajax({
        url: this.build_url,
        dataType: 'json',
        success: function(build_data) {
          $('.js-build-output').html(build_data.trace_html);
          if (build_data.status === 'success' || build_data.status === 'failed') {
            return $('.js-build-refresh').remove();
          }
        }
      });
    };

    Build.prototype.getBuildTrace = function() {
      return $.ajax({
        url: this.page_url + "/trace.json?state=" + (encodeURIComponent(this.state)),
        dataType: "json",
        success: (function(_this) {
          return function(log) {
            if (log.state) {
              _this.state = log.state;
            }
            if (log.status === "running") {
              if (log.append) {
                $('.js-build-output').append(log.html);
              } else {
                $('.js-build-output').html(log.html);
              }
              return _this.checkAutoscroll();
            } else if (log.status !== _this.build_status) {
              return Turbolinks.visit(_this.page_url);
            }
          };
        })(this)
      });
    };

    Build.prototype.checkAutoscroll = function() {
      if ("enabled" === $("#autoscroll-button").data("state")) {
        return $("html,body").scrollTop($("#build-trace").height());
      }
    };

    Build.prototype.initScrollButtonAffix = function() {
      var $body, $buildScroll, $buildTrace;
      $buildScroll = $('#js-build-scroll');
      $body = $('body');
      $buildTrace = $('#build-trace');
      return $buildScroll.affix({
        offset: {
          bottom: function() {
            return $body.outerHeight() - ($buildTrace.outerHeight() + $buildTrace.offset().top);
          }
        }
      });
    };

    Build.prototype.shouldHideSidebar = function() {
      var bootstrapBreakpoint;
      bootstrapBreakpoint = this.bp.getBreakpointSize();
      return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
    };

    Build.prototype.toggleSidebar = function() {
      if (this.shouldHideSidebar()) {
        return $('.js-build-sidebar').toggleClass('right-sidebar-expanded right-sidebar-collapsed');
      }
    };

    Build.prototype.hideSidebar = function() {
      if (this.shouldHideSidebar()) {
        return $('.js-build-sidebar').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
      } else {
        return $('.js-build-sidebar').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');
      }
    };

    Build.prototype.updateArtifactRemoveDate = function() {
      var $date, date;
      $date = $('.js-artifacts-remove');
      if ($date.length) {
        date = $date.text();
        return $date.text($.timefor(new Date(date.replace(/-/g, '/')), ' '));
      }
    };

    Build.prototype.populateJobDropdown = function(stage) {
      $('.build-job').hide();
      $('.build-job[data-stage="' + stage + '"]').show();
    };

    Build.prototype.updateStageDropdownText = function(stage) {
      $('.stage-selection').text(stage);
      this.updateJobDropdownText('-');
    };

    Build.prototype.updateJobDropdownText = function(name) {
      $('.build-selection').text(name);
    };

    Build.prototype.updateDropdown = function(e) {
      e.preventDefault();
      var stage = e.target.text;
      this.updateStageDropdownText(stage);
      this.populateJobDropdown(stage);
    };

    return Build;

  })();

}).call(this);
