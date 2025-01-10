import { createAlert } from '~/alert';
import axios from './lib/utils/axios_utils';
import { parseBoolean } from './lib/utils/common_utils';
import { __ } from './locale';
import { visitUrl } from './lib/utils/url_utility';

const DEFERRED_LINK_CLASS = '.deferred-link';

export default class PersistentUserCallout {
  constructor(container, options = container.dataset) {
    const { dismissEndpoint, featureId, groupId, projectId, deferLinks } = options;
    this.container = container;
    this.dismissEndpoint = dismissEndpoint;
    this.featureId = featureId;
    this.groupId = groupId;
    this.projectId = projectId;
    this.deferLinks = parseBoolean(deferLinks);
    this.closeButtons = this.container.querySelectorAll('.js-close');

    this.init();
  }

  init() {
    const followLink = this.container.querySelector('.js-follow-link');

    if (this.closeButtons.length) {
      this.handleCloseButtonCallout();
    } else if (followLink) {
      this.handleFollowLinkCallout(followLink);
    }
  }

  handleCloseButtonCallout() {
    this.closeButtons.forEach((closeButton) => {
      closeButton.addEventListener('click', this.dismiss);
    });

    if (this.deferLinks) {
      this.container.addEventListener('click', (event) => {
        const deferredLinkEl = event.target.closest(DEFERRED_LINK_CLASS);
        if (deferredLinkEl) {
          const { href, target } = deferredLinkEl;

          this.dismiss(event, { href, target });
        }
      });
    }
  }

  handleFollowLinkCallout(followLink) {
    followLink.addEventListener('click', (event) => this.registerCalloutWithLink(event));
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
        this.container.remove();
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

  registerCalloutWithLink(event) {
    event.preventDefault();

    const { href } = event.currentTarget;

    axios
      .post(this.dismissEndpoint, {
        feature_name: this.featureId,
      })
      .then(() => {
        window.location.assign(href);
      })
      .catch(() => {
        createAlert({
          message: __(
            'An error occurred while acknowledging the notification. Refresh the page and try again.',
          ),
        });
      });
  }

  static factory(container, options) {
    if (!container) {
      return undefined;
    }

    return new PersistentUserCallout(container, options);
  }
}
