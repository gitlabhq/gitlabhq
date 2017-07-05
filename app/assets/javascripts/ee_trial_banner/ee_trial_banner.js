import Cookies from 'js-cookie';

export default class EETrialBanner {
  constructor($trialBanner) {
    this.COOKIE_KEY = 'show_ee_trial_banner';
    this.$trialBanner = $trialBanner;
    this.$navbar = this.$trialBanner.siblings('.js-navbar-gitlab');

    this.licenseExpiresOn = new Date(this.$trialBanner.data('license-expiry'));
  }

  init() {
    const today = new Date();

    // Check if Cookie is defined
    if (!Cookies.get(this.COOKIE_KEY)) {
      // Cookie was not defined, let's define with default value

      // Check if License is yet to expire
      if (today < this.licenseExpiresOn) {
        // License has not expired yet, we show initial banner of 7 days
        // with cookie set to validity same as license expiry
        Cookies.set(this.COOKIE_KEY, 'true', { expires: this.licenseExpiresOn });
      } else {
        // License is already expired so we show final Banner with cookie set to 20 years validity.
        Cookies.set(this.COOKIE_KEY, 'true', { expires: 7300 });
      }

      this.toggleBanner(true);
    } else {
      // Cookie was defined, let's read value and show/hide banner
      this.toggleBanner(Cookies.get(this.COOKIE_KEY) === 'true');
    }

    this.$trialBanner.on('close.bs.alert', e => this.handleTrialBannerDismiss(e));
  }

  toggleBanner(state) {
    if (state) {
      this.$trialBanner.removeClass('hidden');
      this.$navbar.addClass('has-trial-banner');
    } else {
      this.$trialBanner.addClass('hidden');
      this.$navbar.removeClass('has-trial-banner');
    }
  }

  handleTrialBannerDismiss() {
    this.$navbar.removeClass('has-trial-banner');
    if (Cookies.get(this.COOKIE_KEY)) {
      Cookies.set(this.COOKIE_KEY, 'false');
    }
  }
}
