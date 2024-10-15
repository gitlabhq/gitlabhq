import fuzzaldrinPlus from 'fuzzaldrin-plus';
import axios from '~/lib/utils/axios_utils';

import { MAX_LIST_SIZE } from '../constants';

export class AutocompleteCache {
  constructor() {
    this.cache = new Map();
    this.mutators = new Map();
    this.formatters = new Map();
    this.searchProperties = new Map();
  }

  setUpCache({ url, property, mutator, formatter }) {
    this.mutators.set(url, mutator);
    this.formatters.set(url, formatter);
    this.searchProperties.set(url, property);
  }

  async fetch({ url, searchProperty, search, mutator, formatter }) {
    this.setUpCache({ url, property: searchProperty, mutator, formatter });

    if (!this.cache.has(url)) {
      await this.updateLocalCache(url);
    }

    return this.retrieveFromLocalCache(url, search);
  }

  async updateLocalCache(url) {
    const mutator = this.mutators.get(url);

    return axios.get(url).then(({ data }) => {
      let finalData = data;

      if (mutator) {
        finalData = mutator(finalData);
      }

      this.cache.set(url, finalData);
    });
  }

  retrieveFromLocalCache(url, search) {
    const searchProperty = this.searchProperties.get(url);
    const formatter = this.formatters.get(url);
    let result = search
      ? fuzzaldrinPlus.filter(this.cache.get(url), search, { key: searchProperty })
      : this.cache.get(url).slice(0, MAX_LIST_SIZE);

    if (formatter) {
      result = formatter(result);
    }

    return result;
  }
}
