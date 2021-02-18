import { mount } from '@vue/test-utils';
import { UPGRADE_CTA } from '~/security_configuration/components/features_constants';
import Upgrade from '~/security_configuration/components/upgrade.vue';

let wrapper;
const createComponent = () => {
  wrapper = mount(Upgrade, {});
};

beforeEach(() => {
  createComponent();
});

afterEach(() => {
  wrapper.destroy();
});

describe('Upgrade component', () => {
  it('renders correct text in link', () => {
    expect(wrapper.text()).toMatchInterpolatedText(UPGRADE_CTA);
  });

  it('renders link with correct attributes', () => {
    expect(wrapper.find('a').attributes()).toMatchObject({
      href: 'https://about.gitlab.com/pricing/',
      target: '_blank',
    });
  });
});
