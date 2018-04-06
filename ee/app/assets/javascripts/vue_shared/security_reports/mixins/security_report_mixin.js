import { sprintf, s__ } from '~/locale';

export default {
  computed: {
    sastPopover() {
      return {
        title: s__('ciReport|Static Application Security Testing (SAST) detects known vulnerabilities in your source code.'),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about SAST %{linkEndTag}'),
          {
            linkStartTag: `<a href="${this.sastHelpPath}">`,
            linkEndTag: '</a>',
          },
          false,
        ),
      };
    },
    sastContainerPopover() {
      return {
        title: s__('ciReport|Container scanning detects known vulnerabilities in your docker images.'),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about SAST image %{linkEndTag}'),
          {
            linkStartTag: `<a href="${this.sastContainerHelpPath}">`,
            linkEndTag: '</a>',
          },
          false,
        ),
      };
    },
    dastPopover() {
      return {
        title: s__('ciReport|Dynamic Application Security Testing (DAST) detects known vulnerabilities in your web application.'),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about DAST %{linkEndTag}'),
          {
            linkStartTag: `<a href="${this.dastHelpPath}">`,
            linkEndTag: '</a>',
          },
          false,
        ),
      };
    },
    dependencyScanningPopover() {
      return {
        title: s__('ciReport|Dependency Scanning detects known vulnerabilities in your source code\'s dependencies.'),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about Dependency Scanning %{linkEndTag}'),
          {
            linkStartTag: `<a href="${this.dependencyScanningHelpPath}">`,
            linkEndTag: '</a>',
          },
          false,
        ),
      };
    },
  },
};
