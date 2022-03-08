'use strict';

const axios = require('axios');

exports.getMetadata = (endpoint) => {
  const url = endpoint.url;

  return axios
    .request({
      method: 'GET',
      baseURL: url,
      url: '/diffs_metadata.json',
      headers: { Accept: '*/*' },
    })
    .then((response) => response.data);
};

exports.getDiscussions = (endpoint) => {
  const url = endpoint.url;

  return axios
    .request({
      method: 'GET',
      baseURL: url,
      url: '/discussions.json',
      headers: { Accept: '*/*' },
    })
    .then((response) => response.data);
};

exports.getDiffs = (endpoint) => {
  const url = endpoint.url;

  return axios
    .request({
      method: 'GET',
      baseURL: url,
      url: '/diffs_batch.json?page=0',
      headers: { Accept: '*/*' },
    })
    .then((response) => response.data);
};
