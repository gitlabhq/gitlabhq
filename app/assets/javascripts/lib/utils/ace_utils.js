/* global ace */

export default function getModeByFileExtension(path) {
  const modelist = ace.require('ace/ext/modelist');
  return modelist.getModeForPath(path).mode;
}
