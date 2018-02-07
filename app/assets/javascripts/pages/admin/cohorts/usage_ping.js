import axios from '../../../lib/utils/axios_utils';
import { __ } from '../../../locale';
import flash from '../../../flash';

export default function UsagePing() {
  const el = document.querySelector('.usage-data');

  axios.get(el.dataset.endpoint, {
    responseType: 'text',
  }).then(({ data }) => {
    el.innerHTML = data;
  }).catch(() => flash(__('Error fetching usage ping data.')));
}
