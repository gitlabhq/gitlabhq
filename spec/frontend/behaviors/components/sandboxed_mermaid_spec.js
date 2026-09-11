import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import SandboxedMermaid from '~/behaviors/components/sandboxed_mermaid.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('SandboxedMermaid', () => {
  let wrapper;

  const href = 'https://docs.gitlab.com/user/markdown/';

  const findIframe = () => wrapper.find('iframe[src*="/-/sandbox/mermaid"]');

  const createComponent = () => {
    wrapper = shallowMount(SandboxedMermaid, {
      propsData: { source: 'graph LR' },
    });
  };

  const receiveMessage = async (data, { origin = 'null', source } = {}) => {
    window.dispatchEvent(
      new MessageEvent('message', {
        data,
        origin,
        source: source !== undefined ? source : findIframe().element.contentWindow,
      }),
    );
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  it('sets the iframe height from a valid message', async () => {
    expect(findIframe().attributes('height')).toBe('10');

    await receiveMessage({ h: 500, w: 800 });

    expect(findIframe().attributes('height')).toBe('510');
  });

  // Exhaustive height payload cases live in render_sandboxed_mermaid_spec.js; this just checks the wiring.
  it('ignores a message with an invalid height payload', async () => {
    expect(findIframe().attributes('height')).toBe('10');

    await receiveMessage({ h: 500, w: 800 });
    await receiveMessage({
      command: 'registerAsChildFrameAck',
      remoteFrameId: '4547d9da50e1d06103b42b3e2a64ee86',
    });

    expect(findIframe().attributes('height')).toBe('510');
  });

  describe('link click messages from the sandboxed iframe', () => {
    it('opens an http(s) link in a new tab', async () => {
      await receiveMessage({ href });

      expect(visitUrl).toHaveBeenCalledWith(href, true);
    });

    // Exhaustive URL validation cases live in render_sandboxed_mermaid_spec.js; this just checks the wiring.
    it('does not open an unsafe URL', async () => {
      // eslint-disable-next-line no-script-url
      await receiveMessage({ href: 'javascript:alert(1)' });

      expect(visitUrl).not.toHaveBeenCalled();
    });
  });

  describe('sandbox message protocol', () => {
    it('treats a message with both link and height payloads as a link click', async () => {
      await receiveMessage({ href, h: 500 });

      expect(visitUrl).toHaveBeenCalledWith(href, true);
      expect(findIframe().attributes('height')).toBe('10');
    });

    it.each`
      description                      | overrides
      ${'an unexpected origin'}        | ${{ origin: 'https://evil.example.com' }}
      ${'an unexpected source window'} | ${{ source: window }}
    `('ignores messages from $description', async ({ overrides }) => {
      await receiveMessage({ href }, overrides);
      await receiveMessage({ h: 500, w: 800 }, overrides);

      expect(visitUrl).not.toHaveBeenCalled();
      expect(findIframe().attributes('height')).toBe('10');
    });
  });
});
