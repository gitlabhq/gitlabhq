import { shallowMount } from '@vue/test-utils';
import { GlButton, GlForm } from '@gitlab/ui';
import RevokeOauth, {
  GOOGLE_CLOUD_REVOKE_TITLE,
  GOOGLE_CLOUD_REVOKE_DESCRIPTION,
} from '~/google_cloud/components/revoke_oauth.vue';

describe('google_cloud/components/revoke_oauth', () => {
  let wrapper;

  const findTitle = () => wrapper.find('h2');
  const findDescription = () => wrapper.find('p');
  const findForm = () => wrapper.findComponent(GlForm);
  const findButton = () => wrapper.findComponent(GlButton);
  const propsData = {
    url: 'url_general_feedback',
  };

  beforeEach(() => {
    wrapper = shallowMount(RevokeOauth, { propsData });
  });

  it('contains title', () => {
    const title = findTitle();
    expect(title.text()).toContain('Revoke authorizations');
  });

  it('contains description', () => {
    const description = findDescription();
    expect(description.text()).toContain(GOOGLE_CLOUD_REVOKE_DESCRIPTION);
  });

  it('contains form', () => {
    const form = findForm();
    expect(form.attributes('action')).toBe(propsData.url);
    expect(form.attributes('method')).toBe('post');
  });

  it('contains button', () => {
    const button = findButton();
    expect(button.text()).toContain(GOOGLE_CLOUD_REVOKE_TITLE);
  });
});
