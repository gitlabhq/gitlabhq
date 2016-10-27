/* eslint-disable */
(function() {
  this.Star = (function() {
    function Star() {
      $('.project-home-panel .toggle-star').on('ajax:success', function(e, data, status, xhr) {
        var $starIcon, $starSpan, $this, toggleStar;
        $this = $(this);
        $starSpan = $this.find('span');
        $starIcon = $this.find('i');
        toggleStar = function(isStarred) {
          $this.parent().find('.star-count').text(data.star_count);
          if (isStarred) {
            $starSpan.removeClass('starred').text('Star');
            gl.utils.updateTooltipTitle($this, 'Star project');
            $starIcon.removeClass('fa-star').addClass('fa-star-o');
          } else {
            $starSpan.addClass('starred').text('Unstar');
            gl.utils.updateTooltipTitle($this, 'Unstar project');
            $starIcon.removeClass('fa-star-o').addClass('fa-star');
          }
        };
        toggleStar($starSpan.hasClass('starred'));
      }).on('ajax:error', function(e, xhr, status, error) {
        new Flash('Star toggle failed. Try again later.', 'alert');
      });
    }

    return Star;

  })();

}).call(this);
