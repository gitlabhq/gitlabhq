import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { MAX_LIST_SIZE } from '~/issues/list/constants';
import axios from '~/lib/utils/axios_utils';

export class AutocompleteCache {
  constructor() {
    this.cache = {};
  }

  fetch({ url, cacheName, searchProperty, search }) {
    if (this.cache[cacheName]) {
      const data = search
        ? fuzzaldrinPlus.filter(this.cache[cacheName], search, { key: searchProperty })
        : this.cache[cacheName].slice(0, MAX_LIST_SIZE);
      return Promise.resolve(data);
    }

    return axios.get(url).then(({ data }) => {
      this.cache[cacheName] = data;
      return data.slice(0, MAX_LIST_SIZE);
    });
  }
}
