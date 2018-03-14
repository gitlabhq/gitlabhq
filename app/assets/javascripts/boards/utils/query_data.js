import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';

export default (path, extraData) => path.split('&').reduce((dataParam, filterParam) => {
  if (filterParam === '') return dataParam;

  const data = dataParam;
  const paramSplit = filterParam.split('=');
  const paramKeyNormalized = paramSplit[0].replace('[]', '');
  const isArray = paramSplit[0].includes('[]');

  let value = paramSplit[1];

  if (FilteredSearchTokenKeys.searchByConditionUrl(dataParam)) {
    value = decodeURIComponent(value).replace(/\+/g, ' ');
  } else {
    value = decodeURIComponent(value.replace(/\+/g, ' '));
  }

  if (isArray) {
    if (!data[paramKeyNormalized]) {
      data[paramKeyNormalized] = [];
    }

    data[paramKeyNormalized].push(value);
  } else {
    data[paramKeyNormalized] = value;
  }

  return data;
}, extraData);
