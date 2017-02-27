/* global Cookies */

const userCalloutElementName = '.user-callout';
const closeButton = '.close-user-callout';
const userCalloutBtn = '.user-callout-btn';
const userCalloutSvgAttrName = 'callout-svg';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

const USER_CALLOUT_TEMPLATE = `
  <div class="bordered-box landing content-block">
    <button class="btn btn-default close close-user-callout" type="button">
      <i class="fa fa-times dismiss-icon"></i>
    </button>
    <div class="row">
      <div class="col-sm-3 col-xs-12 svg-container">
      </div>
      <div class="col-sm-8 col-xs-12 inner-content">
        <h4>
          Customize your experience
        </h4>
        <p>
          Change syntax themes, default project pages, and more in preferences.
        </p>
        <a class="btn user-callout-btn" href="/profile/preferences">Check it out</a>
      </div>
  </div>
</div>`;

class UserCallout {
  constructor() {
    this.isCalloutDismissed = Cookies.get(USER_CALLOUT_COOKIE);
    this.userCalloutBody = $(userCalloutElementName);
    this.userCalloutSvg = $(userCalloutElementName).attr(userCalloutSvgAttrName);
    $(userCalloutElementName).removeAttr(userCalloutSvgAttrName);
    this.init();
  }

  init() {
    const $template = $(USER_CALLOUT_TEMPLATE);
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      $template.find('.svg-container').append(this.userCalloutSvg);
      this.userCalloutBody.append($template);
      $template.find(closeButton).on('click', e => this.dismissCallout(e));
      $template.find(userCalloutBtn).on('click', e => this.dismissCallout(e));
    }
  }

  dismissCallout(e) {
    Cookies.set(USER_CALLOUT_COOKIE, 'true');
    const $currentTarget = $(e.currentTarget);
    if ($currentTarget.hasClass('close-user-callout')) {
      this.userCalloutBody.empty();
    }
  }
}

module.exports = UserCallout;
