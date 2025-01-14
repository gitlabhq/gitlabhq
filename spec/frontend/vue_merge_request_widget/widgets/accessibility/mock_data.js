export const accessibilityReportResponseErrors = {
  status: 'failed',
  new_errors: [
    {
      code: 'WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1',
      type: 'error',
      type_code: 1,
      message: 'Iframe element requires a non-empty title attribute that identifies the frame.',
      context:
        '<iframe height="0" width="0" style="display: none; visibility: hidden;" src="//10421980.fls.doubleclick.net/activityi;src=10421980;type=count0;cat=globa0;ord=6271888671448;gtm=2wg1c0;auiddc=40010797.1642181125;u1=undefined;u2=undefined;u3=undefined;u...',
      selector: 'html > body > iframe:nth-child(42)',
      runner: 'htmlcs',
      runner_extras: {},
    },
    {
      code: 'WCAG2AA.Principle3.Guideline3_2.3_2_2.H32.2',
      type: 'error',
      type_code: 1,
      message:
        'This form does not contain a submit button, which creates issues for those who cannot submit the form using the keyboard. Submit buttons are INPUT elements with type attribute "submit" or "image", or BUTTON elements with type "submit" or omitted/invalid.',
      context:
        '<form class="challenge-form" id="challenge-form" action="/users/sign_in?__cf_chl_jschl_tk__=xoagAHj9DXTTDveypAmMkakkNQgeWc6LmZA53YyDeSg-1642181129-0-gaNycGzNB1E" method="POST" enctype="application/x-www-form-urlencoded">\n    <input type="hidden" name...',
      selector: '#challenge-form',
      runner: 'htmlcs',
      runner_extras: {},
    },
    {
      code: 'WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1',
      type: 'error',
      type_code: 1,
      message: 'Iframe element requires a non-empty title attribute that identifies the frame.',
      context: '<iframe style="display: none;"></iframe>',
      selector: 'html > body > iframe',
      runner: 'htmlcs',
      runner_extras: {},
    },
  ],
  resolved_errors: [
    {
      code: 'WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1',
      type: 'error',
      type_code: 1,
      message: 'Iframe element requires a non-empty title attribute that identifies the frame.',
      context:
        '<iframe height="0" width="0" style="display: none; visibility: hidden;" src="//10421980.fls.doubleclick.net/activityi;src=10421980;type=count0;cat=globa0;ord=6722452746146;gtm=2wg1a0;auiddc=716711306.1642082367;u1=undefined;u2=undefined;u3=undefined;...',
      selector: 'html > body > iframe:nth-child(42)',
      runner: 'htmlcs',
      runner_extras: {},
    },
    {
      code: 'WCAG2AA.Principle3.Guideline3_2.3_2_2.H32.2',
      type: 'error',
      type_code: 1,
      message:
        'This form does not contain a submit button, which creates issues for those who cannot submit the form using the keyboard. Submit buttons are INPUT elements with type attribute "submit" or "image", or BUTTON elements with type "submit" or omitted/invalid.',
      context:
        '<form class="challenge-form" id="challenge-form" action="/users/sign_in?__cf_chl_jschl_tk__=vDKZT2hjxWCstlWz2wtxsLdqLF79rM4IsoxzMgY6Lfw-1642082370-0-gaNycGzNB2U" method="POST" enctype="application/x-www-form-urlencoded">\n    <input type="hidden" name...',
      selector: '#challenge-form',
      runner: 'htmlcs',
      runner_extras: {},
    },
  ],
  existing_errors: [
    {
      code: 'WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2',
      type: 'error',
      type_code: 1,
      message:
        'Img element is the only content of the link, but is missing alt text. The alt text should describe the purpose of the link.',
      context: '<a href="/" data-nav="logo">\n<img src="/images/icons/logos/...</a>',
      selector: '#navigation-mobile > header > a',
      runner: 'htmlcs',
      runner_extras: {},
    },
    {
      code: 'WCAG2AA.Principle1.Guideline1_1.1_1_1.H37',
      type: 'error',
      type_code: 1,
      message:
        'Img element missing an alt attribute. Use the alt attribute to specify a short text alternative.',
      context: '<img src="/images/icons/slp-hamburger.svg" class="slp-inline-block slp-mr-8">',
      selector: '#slpMobileNavActive > img',
      runner: 'htmlcs',
      runner_extras: {},
    },
  ],
  summary: {
    total: 7,
    resolved: 2,
    errored: 5,
  },
};

export const accessibilityReportResponseSuccess = {
  status: 'success',
  new_errors: [],
  resolved_errors: [],
  existing_errors: [],
  summary: {
    total: 0,
    resolved: 0,
    errored: 0,
  },
};
