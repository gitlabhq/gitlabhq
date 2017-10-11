<<<<<<< HEAD
/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-unused-vars, one-var, no-var, one-var-declaration-per-line, prefer-arrow-callback, no-new, max-len */
=======
>>>>>>> upstream/master
import Flash from './flash';
import { __, s__ } from './locale';

export default class Star {
  constructor() {
    $('.project-home-panel .toggle-star')
      .on('ajax:success', function handleSuccess(e, data) {
        const $this = $(this);
        const $starSpan = $this.find('span');
        const $starIcon = $this.find('i');

        function toggleStar(isStarred) {
          $this.parent().find('.star-count').text(data.star_count);
          if (isStarred) {
            $starSpan.removeClass('starred').text(s__('StarProject|Star'));
            $starIcon.removeClass('fa-star').addClass('fa-star-o');
          } else {
            $starSpan.addClass('starred').text(__('Unstar'));
            $starIcon.removeClass('fa-star-o').addClass('fa-star');
          }
        }

        toggleStar($starSpan.hasClass('starred'));
      })
      .on('ajax:error', () => {
        Flash('Star toggle failed. Try again later.', 'alert');
      });
  }
}
