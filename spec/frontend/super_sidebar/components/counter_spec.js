import { GlIcon } from '@gitlab/ui';
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

  const findButton = () => wrapper.find('button');
  const findIcon = () => wrapper.getComponent(GlIcon);
  const findLink = () => wrapper.find('a');

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
      expect(findIcon().props('name')).toBe('issues');
    });

    it('renders button', () => {
      expect(findButton().attributes('aria-label')).toBe('Issues 3');
      expect(findLink().exists()).toBe(false);
    });
  });

  describe('link', () => {
    it('renders link', () => {
      createWrapper({ href: '/dashboard/todos' });
      expect(findLink().attributes('aria-label')).toBe('Issues 3');
      expect(findLink().attributes('href')).toBe('/dashboard/todos');
      expect(findButton().exists()).toBe(false);
    });
  });

  it.each([
    ['99+', '99+'],
    ['110%', '110%'],
    [100, '99+'],
    [10, '10'],
    [0, ''],
  ])('formats count %p as %p', (count, result) => {
    createWrapper({ count });
    expect(findButton().text()).toBe(result);
  });
});
