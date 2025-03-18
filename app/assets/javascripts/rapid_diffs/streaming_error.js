import { createAlert } from '~/alert';
import { __ } from '~/locale';

export class StreamingError extends HTMLElement {
  connectedCallback() {
    const message = __(`Could not fetch all changes. Try reloading the page.`);
    // eslint-disable-next-line no-console
    console.error(`Failed to stream diffs: ${this.getAttribute('message')}`);
    createAlert({ message });
  }
}
