import { StreamingError } from '~/rapid_diffs/streaming_error';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('DiffFile Web Component', () => {
  const html = `
    <streaming-error message="Foo">
    </streaming-error>
  `;

  const renderComponent = () => {
    document.body.innerHTML = html;
  };

  beforeAll(() => {
    customElements.define('streaming-error', StreamingError);
  });

  it('creates an alert', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    renderComponent();
    expect(spy).toHaveBeenCalledWith('Failed to stream diffs: Foo');
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Could not fetch all changes. Try reloading the page.',
    });
  });
});
