import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import SandboxedMermaid from '~/behaviors/components/sandboxed_mermaid.vue';

describe('SandboxedMermaid', () => {
  let wrapper;

  const findIframe = () => wrapper.find('iframe[src*="/-/sandbox/mermaid"]');

  const createComponent = () => {
    wrapper = shallowMount(SandboxedMermaid, {
      propsData: { source: 'graph LR' },
    });
  };

  const postMessageFromIframe = async (data) => {
    window.dispatchEvent(
      new MessageEvent('message', {
        data,
        origin: 'null',
        source: findIframe().element.contentWindow,
      }),
    );
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  it('sets the iframe height from a valid message', async () => {
    expect(findIframe().attributes('height')).toBe('10');

    await postMessageFromIframe({ h: 500, w: 800 });

    expect(findIframe().attributes('height')).toBe('510');
  });

  it.each`
    description                              | data
    ${'no h (the ack Chrome for iOS posts)'} | ${{ command: 'registerAsChildFrameAck', remoteFrameId: '4547d9da50e1d06103b42b3e2a64ee86' }}
    ${'a numeric-string h'}                  | ${{ h: '999' }}
    ${'a null h'}                            | ${{ h: null }}
    ${'an empty-string h'}                   | ${{ h: '' }}
    ${'an undefined payload'}                | ${undefined}
  `('ignores a message with $description', async ({ data }) => {
    expect(findIframe().attributes('height')).toBe('10');

    await postMessageFromIframe({ h: 500, w: 800 });
    await postMessageFromIframe(data);

    expect(findIframe().attributes('height')).toBe('510');
  });

  it('ignores a message from another window', async () => {
    expect(findIframe().attributes('height')).toBe('10');

    await postMessageFromIframe({ h: 500, w: 800 });

    window.dispatchEvent(
      new MessageEvent('message', { data: { h: 40 }, origin: 'null', source: window }),
    );
    await nextTick();

    expect(findIframe().attributes('height')).toBe('510');
  });
});
