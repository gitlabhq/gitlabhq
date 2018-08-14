import $ from 'jquery';
import Flash from './flash';
import { __, s__ } from './locale';
import { spriteIcon } from './lib/utils/common_utils';
import axios from './lib/utils/axios_utils';

export default class Star {
  constructor() {
    $('.project-home-panel .toggle-star').on('click', function toggleStarClickCallback() {
      const $this = $(this);
      const $starSpan = $this.find('span');
      const $startIcon = $this.find('svg');

      axios.post($this.data('endpoint'))
        .then(({ data }) => {
          const isStarred = $starSpan.hasClass('starred');
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
        })
        .catch(() => Flash('Star toggle failed. Try again later.'));
    });
  }
}
