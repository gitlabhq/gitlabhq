import $ from 'jquery';
import flash from '~/flash';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export default function initPathLocks(url, path) {
  $('a.path-lock').on('click', (e) => {
    e.preventDefault();

    axios.post(url, {
      path,
    }).then(() => {
      location.reload();
    }).catch(() => flash(__('An error occurred while initializing path locks')));
  });
}
