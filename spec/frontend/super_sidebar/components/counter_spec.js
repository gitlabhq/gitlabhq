import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Counter from '~/super_sidebar/components/counter.vue';

describe('Counter component', () => {
  let wrapper;

  const defaultPropsData = {
    count: 3,
    href: '',
    icon: 'issues',
    label: 'Issues',
  };

  const findButton = () => wrapper.getComponent(GlButton);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(Counter, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('default', () => {
    it('renders icon', () => {
      expect(findButton().props('icon')).toBe('issues');
    });

    it('renders button', () => {
      expect(findButton().attributes('aria-label')).toBe('3 Issues');
    });
  });

  describe('link', () => {
    it('renders as a link', () => {
      createWrapper({ href: '/dashboard/todos' });
      expect(findButton().attributes('aria-label')).toBe('3 Issues');
      expect(findButton().attributes('href')).toBe('/dashboard/todos');
    });
  });

  it.each([
    ['99+', '99+'],
    ['110%', '110%'],
    [100, '99+'],
    [10, '10'],
    [0, '0'],
  ])('formats count %p as %p', (count, result) => {
    createWrapper({ count });
    expect(findButton().text()).toBe(result);
  });
});
