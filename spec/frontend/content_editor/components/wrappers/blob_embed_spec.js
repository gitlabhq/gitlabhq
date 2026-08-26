import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobEmbedWrapper from '~/content_editor/components/wrappers/blob_embed.vue';

describe('content_editor/components/wrappers/blob_embed', () => {
  const SHA = '0'.repeat(40);
  const baseUrl = `http://test.host/group/project/-/blob/${SHA}/dir/file.rb`;

  let wrapper;

  const createWrapper = ({ url, text = null, range = '' } = {}) => {
    wrapper = shallowMountExtended(BlobEmbedWrapper, {
      propsData: { node: { attrs: { url, text, range } } },
      stubs: { NodeViewWrapper: { template: '<div><slot /></div>' } },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  it('shows the server-rendered title (mirroring the cross-project qualifier) and range', () => {
    createWrapper({
      url: `${baseUrl}#L3-6`,
      text: 'group/other-project/dir/file.rb',
      range: 'Lines 3 to 6',
    });

    expect(wrapper.text()).toContain('group/other-project/dir/file.rb');
    expect(wrapper.text()).toContain('Lines 3 to 6');
  });

  it('links to the source file in a new tab (rather than navigating the editor)', () => {
    createWrapper({ url: `${baseUrl}#L3-6`, range: 'Lines 3 to 6' });

    expect(findLink().attributes('href')).toBe(`${baseUrl}#L3-6`);
    expect(findLink().attributes('target')).toBe('_blank');
  });

  describe('when no title is present', () => {
    it('falls back to the file path derived from the URL', () => {
      createWrapper({ url: `${baseUrl}#L3-6`, range: 'Lines 3 to 6' });

      expect(wrapper.text()).toContain('dir/file.rb');
    });
  });

  describe('when the server clamped the range to the length of the file', () => {
    it('shows the range the server rendered, not the one in the permalink', () => {
      createWrapper({ url: `${baseUrl}#L3-600`, range: 'Lines 3 to 6' });

      expect(wrapper.text()).toContain('Lines 3 to 6');
      expect(wrapper.text()).not.toContain('600');
    });
  });
});
