import { createAlert } from '~/alert';
import axios from './lib/utils/axios_utils';
import { parseBoolean } from './lib/utils/common_utils';
import { __ } from './locale';
import { visitUrl } from './lib/utils/url_utility';

/**
 * Integrates with server-side rendered callouts, adding dismissing interaction to them.
 * See https://docs.gitlab.com/development/callouts/#server-side-rendered-callouts
 */
export default class PersistentUserCallout {
  constructor(container, options = container.dataset) {
    const { dismissEndpoint, featureId, groupId, projectId, deferLinks } = options;
    this.container = container;
    this.dismissEndpoint = dismissEndpoint;
    this.featureId = featureId;
    this.groupId = groupId;
    this.projectId = projectId;
    this.storageKey = this.createStorageKey();
    this.deferLinks = parseBoolean(deferLinks);
    this.closeButtons = this.container.querySelectorAll('.js-close');
    this.calloutElement = parseBoolean(this.container.dataset.hasWrapper)
      ? this.container.parentElement
      : this.container;

    this.init();
  }

  createStorageKey() {
    return ['user_callout_dismissed', this.projectId || this.groupId, this.featureId]
      .filter(Boolean)
      .join('_');
  }

  init() {
    if (sessionStorage.getItem(this.storageKey)) {
      this.calloutElement?.remove();
      return;
    }

    this.closeButtons.forEach((closeButton) => {
      closeButton.addEventListener('click', this.dismiss);
    });

    if (this.closeButtons.length && this.deferLinks) {
      this.container.addEventListener('click', (event) => {
        const deferredLinkEl = event.target.closest('.deferred-link');
        if (deferredLinkEl) {
          const { href, target } = deferredLinkEl;

          this.dismiss(event, { href, target });
        }
      });
    }
  }

  dismiss = (event, deferredLinkOptions = null) => {
    event.preventDefault();

    axios
      .post(this.dismissEndpoint, {
        feature_name: this.featureId,
        group_id: this.groupId,
        project_id: this.projectId,
      })
      .then(() => {
        sessionStorage.setItem(this.storageKey, new Date().toISOString());

        this.calloutElement?.remove();

        this.closeButtons.forEach((closeButton) => {
          closeButton.removeEventListener('click', this.dismiss);
        });

        if (deferredLinkOptions) {
          const { href, target } = deferredLinkOptions;
          visitUrl(href, target === '_blank');
        }
      })
      .catch(() => {
        createAlert({
          message: __(
            'An error occurred while dismissing the alert. Refresh the page and try again.',
          ),
        });
      });
  };

  static factory(container, options) {
    if (!container) {
      return undefined;
    }

    return new PersistentUserCallout(container, options);
  }
}
