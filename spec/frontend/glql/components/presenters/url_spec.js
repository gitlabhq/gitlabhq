import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UrlPresenter from '~/glql/components/presenters/url.vue';

describe('UrlPresenter', () => {
  it('renders a link with the URL as both href and text', () => {
    const url = '/gitlab-org/gitlab-shell/-/jobs/2232';
    const wrapper = shallowMountExtended(UrlPresenter, { propsData: { data: url } });

    expect(wrapper.text()).toBe(url);
    expect(wrapper.attributes('href')).toBe(url);
  });
});
