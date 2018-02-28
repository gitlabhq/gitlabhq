export default (path, extraData) => path.split('&').reduce((dataParam, filterParam) => {
  if (filterParam === '') return dataParam;

  const data = dataParam;
  const paramSplit = filterParam.split('=');
  const paramKeyNormalized = paramSplit[0].replace('[]', '');
  const isArray = paramSplit[0].indexOf('[]');
  const value = decodeURIComponent(paramSplit[1].replace(/\+/g, ' '));

  if (isArray !== -1) {
    if (!data[paramKeyNormalized]) {
      data[paramKeyNormalized] = [];
    }

    data[paramKeyNormalized].push(value);
  } else {
    data[paramKeyNormalized] = value;
  }

  return data;
}, extraData);
