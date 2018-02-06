import Flash from './flash';
import { __, s__ } from './locale';
import { spriteIcon } from './lib/utils/common_utils';

export default class Star {
  constructor() {
    $('.project-home-panel .toggle-star')
      .on('ajax:success', function handleSuccess(e, data) {
        const $this = $(this);
        const $starSpan = $this.find('span');
        const $startIcon = $this.find('svg');

        function toggleStar(isStarred) {
          $this.parent().find('.star-count').text(data.star_count);
          if (isStarred) {
            $starSpan.removeClass('starred').text(s__('StarProject|Star'));
            $startIcon.remove();
            $this.prepend(spriteIcon('star-o'));
          } else {
            $starSpan.addClass('starred').text(__('Unstar'));
            $startIcon.remove();
            $this.prepend(spriteIcon('star'));
          }
        }

        toggleStar($starSpan.hasClass('starred'));
      })
      .on('ajax:error', () => {
        Flash('Star toggle failed. Try again later.', 'alert');
      });
  }
}
