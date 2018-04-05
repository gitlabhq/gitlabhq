import $ from 'jquery';
import VersionCheckImage from '~/version_check_image';
import docs from '~/docs/docs_bundle';

document.addEventListener('DOMContentLoaded', () => {
  docs();
  VersionCheckImage.bindErrorEvent($('img.js-version-status-badge'));
});
