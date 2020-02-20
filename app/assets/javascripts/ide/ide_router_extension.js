import VueRouter from 'vue-router';
import { escapeFileUrl } from '~/lib/utils/url_utility';

// To allow special characters (like "#," for example) in the branch names, we
// should encode all the locations before those get processed by History API.
// Otherwise, paths get messed up so that the router receives incorrect
// branchid. The only way to do it consistently and in a more or less
// future-proof manner is, unfortunately, to monkey-patch VueRouter or, as
// suggested here, achieve the same more reliably by subclassing VueRouter and
// update the methods, used in WebIDE.
//
// More context: https://gitlab.com/gitlab-org/gitlab/issues/35473

export default class IDERouter extends VueRouter {
  push(location, onComplete, onAbort) {
    super.push(escapeFileUrl(location), onComplete, onAbort);
  }
  resolve(to, current, append) {
    return super.resolve(escapeFileUrl(to), current, append);
  }
}
