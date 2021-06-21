import createFlash from './flash';
import axios from './lib/utils/axios_utils';
import { parseBoolean } from './lib/utils/common_utils';
import { __ } from './locale';

const DEFERRED_LINK_CLASS = 'deferred-link';

export default class PersistentUserCallout {
  constructor(container, options = container.dataset) {
    const { dismissEndpoint, featureId, deferLinks } = options;
    this.container = container;
    this.dismissEndpoint = dismissEndpoint;
    this.featureId = featureId;
    this.deferLinks = parseBoolean(deferLinks);

    this.init();
  }

  init() {
    const closeButton = this.container.querySelector('.js-close');
    const followLink = this.container.querySelector('.js-follow-link');

    if (closeButton) {
      this.handleCloseButtonCallout(closeButton);
    } else if (followLink) {
      this.handleFollowLinkCallout(followLink);
    }
  }

  handleCloseButtonCallout(closeButton) {
    closeButton.addEventListener('click', (event) => this.dismiss(event));

    if (this.deferLinks) {
      this.container.addEventListener('click', (event) => {
        const isDeferredLink = event.target.classList.contains(DEFERRED_LINK_CLASS);
        if (isDeferredLink) {
          const { href, target } = event.target;

          this.dismiss(event, { href, target });
        }
      });
    }
  }

  handleFollowLinkCallout(followLink) {
    followLink.addEventListener('click', (event) => this.registerCalloutWithLink(event));
  }

  dismiss(event, deferredLinkOptions = null) {
    event.preventDefault();

    axios
      .post(this.dismissEndpoint, {
        feature_name: this.featureId,
      })
      .then(() => {
        this.container.remove();

        if (deferredLinkOptions) {
          const { href, target } = deferredLinkOptions;
          window.open(href, target);
        }
      })
      .catch(() => {
        createFlash({
          message: __(
            'An error occurred while dismissing the alert. Refresh the page and try again.',
          ),
        });
      });
  }

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
        createFlash({
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
