import { mount } from '@vue/test-utils';
import { UPGRADE_CTA } from '~/security_configuration/components/constants';
import Upgrade from '~/security_configuration/components/upgrade.vue';

const TEST_URL = 'http://www.example.test';
let wrapper;
const createComponent = (componentData = {}) => {
  wrapper = mount(Upgrade, componentData);
};

afterEach(() => {
  wrapper.destroy();
});

describe('Upgrade component', () => {
  beforeEach(() => {
    createComponent({ provide: { upgradePath: TEST_URL } });
  });

  it('renders correct text in link', () => {
    expect(wrapper.text()).toMatchInterpolatedText(UPGRADE_CTA);
  });

  it('renders link with correct default attributes', () => {
    expect(wrapper.find('a').attributes()).toMatchObject({
      href: TEST_URL,
      target: '_blank',
    });
  });
});
