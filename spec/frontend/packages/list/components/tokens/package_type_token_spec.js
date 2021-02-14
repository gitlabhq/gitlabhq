import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages/list/components/tokens/package_type_token.vue';
import { PACKAGE_TYPES } from '~/packages/list/constants';

describe('packages_filter', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);

  const mountComponent = ({ attrs, listeners } = {}) => {
    wrapper = shallowMount(component, {
      attrs,
      listeners,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('it binds all of his attrs to filtered search token', () => {
    mountComponent({ attrs: { foo: 'bar' } });

    expect(findFilteredSearchToken().attributes('foo')).toBe('bar');
  });

  it('it binds all of his events to filtered search token', () => {
    const clickListener = jest.fn();
    mountComponent({ listeners: { click: clickListener } });

    findFilteredSearchToken().vm.$emit('click');

    expect(clickListener).toHaveBeenCalled();
  });

  it.each(PACKAGE_TYPES.map((p, index) => [p, index]))(
    'displays a suggestion for %p',
    (packageType, index) => {
      mountComponent();
      const item = findFilteredSearchSuggestions().at(index);
      expect(item.text()).toBe(packageType.title);
      expect(item.props('value')).toBe(packageType.type);
    },
  );
});
