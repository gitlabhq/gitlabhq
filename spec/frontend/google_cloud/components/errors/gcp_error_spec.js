import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import GcpError from '~/google_cloud/components/errors/gcp_error.vue';

describe('GcpError component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findBlockquote = () => wrapper.find('blockquote');

  const propsData = { error: 'IAM and CloudResourceManager API disabled' };

  beforeEach(() => {
    wrapper = shallowMount(GcpError, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains alert', () => {
    expect(findAlert().exists()).toBe(true);
  });

  it('contains relevant text', () => {
    const alertText = findAlert().text();
    expect(findAlert().props('title')).toBe(GcpError.i18n.title);
    expect(alertText).toContain(GcpError.i18n.description);
  });

  it('contains error stacktrace', () => {
    expect(findBlockquote().text()).toBe(propsData.error);
  });
});
