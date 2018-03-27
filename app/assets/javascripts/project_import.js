import { visitUrl } from './lib/utils/url_utility';

export default function projectImport() {
  setTimeout(() => {
    visitUrl(location.href);
  }, 5000);
}

