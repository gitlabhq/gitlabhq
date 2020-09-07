import { template } from 'lodash';

/**
 * Generic abstraction for WebAuthnFlows, especially for register / authenticate
 */
export default class WebAuthnFlow {
  constructor(container, templates) {
    this.container = container;
    this.templates = templates;
  }

  renderTemplate(name, params) {
    const templateString = document.querySelector(this.templates[name]).innerHTML;
    const compiledTemplate = template(templateString);
    this.container.html(compiledTemplate(params));
  }

  renderError(error) {
    this.renderTemplate('error', {
      error_message: error.message(),
      error_name: error.errorName,
    });
  }
}
